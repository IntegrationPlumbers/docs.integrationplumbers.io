#!/usr/bin/perl
# Copyright (c) 2026, Integration Plumbers. All rights reserved.
#
# pgBackRest backup history for an Oracle Enterprise Manager metric extension (OS Command - Multiple Columns
# adapter) on the ip_postgresql_db target type. Runs `pgbackrest info --output=json` on the agent host and prints
# ONE em_result row per stanza, pipe-delimited, in this column order (the key column is stanza):
#
#   stanza | status_code | status_message | backups_30d | full_backups_30d | last_backup_label | last_backup_type
#   | last_backup_finished_at | hours_since_last_backup | last_full_backup_age_days | last_backup_duration_seconds
#   | last_backup_repo_size_bytes | backups_with_errors_30d | repo_status | collected_at
#
# What the numbers mean (pgBackRest only lists COMPLETED backups: a backup that failed leaves no entry, so
# "did backups fail" is read from the stanza status code and from the age of the last successful backup):
#   status_code / status_message   pgBackRest's own stanza status (0 ok; 1 missing stanza path; 2 no valid
#                                  backups; 3 missing stanza data; 4 backup/expire running; 99 other).
#   backups_30d / full_backups_30d completed backups (any type / full) that finished in the window (--days).
#   last_backup_*                  the most recently finished backup of any type; hours_since_last_backup is the
#                                  threshold value ("no successful backup for N hours").
#   last_full_backup_age_days      days since the last full backup finished (empty when there is none).
#   last_backup_duration_seconds   stop - start of the last backup; last_backup_repo_size_bytes its size in the
#                                  repository (compressed, after deduplication for diff / incr).
#   backups_with_errors_30d        backups in the window pgBackRest flagged with "error": true (page checksum
#                                  errors found while backing up - the backup completed, the data has a problem).
#   repo_status                    "<key>:<code> <message>" per repository, "; "-joined.
#   collected_at                   when this ran, UTC.
# Without any usable output the script prints ONE em_error line and exits non-zero, so the metric reads as a
# collection error rather than an all-clear.
#
# Options (all optional):
#   --stanza=<name>       only this stanza (default: every stanza pgbackrest reports)
#   --pgbackrest=<path>   the binary (default: pgbackrest, found on PATH)
#   --config=<path>       passed through as --config
#   --repo=<n>            passed through as --repo
#   --days=<n>            the window for the *_30d columns (default 30)
#   --input-file=<json>   read this file instead of running pgbackrest (tests, dry runs, a copied output)
#   --now=<epoch>         "now" for the age computations (tests)
# Needs only core perl (JSON::PP, IPC::Open3, POSIX), as shipped with the agent.
use strict;
use warnings;
use JSON::PP;
use IPC::Open3;
use POSIX qw(strftime);

my %opt = (pgbackrest => 'pgbackrest', days => 30);
my %known = map { $_ => 1 } qw(stanza pgbackrest config repo days input-file now);
foreach my $arg (@ARGV) {
  if ($arg =~ /^--([a-z-]+)=(.*)$/s && $known{$1}) {
    $opt{$1} = $2;
  } elsif ($arg =~ /^--help$/) {
    print "usage: pgbackrest_backup_history.pl [--stanza=NAME] [--pgbackrest=PATH] [--config=PATH] [--repo=N] [--days=N] [--input-file=FILE]\n";
    exit 0;
  } else {
    fail("unknown argument '$arg'");
  }
}
fail("--days must be a positive integer") unless $opt{days} =~ /^\d+$/ && $opt{days} > 0;
my $now = defined $opt{now} && $opt{now} =~ /^\d+$/ ? $opt{now} : time();

my $json_text = defined $opt{'input-file'} ? read_file($opt{'input-file'}) : run_pgbackrest();
# stderr is merged into stdout (see run_pgbackrest), so a WARN line pgbackrest prints on a healthy run
# (log-level-stderr defaults to warn: a missing secondary repository, a deprecated option) can precede
# the JSON. The output is the first line that starts the stanza list; everything before it is log.
$json_text = $1 if $json_text =~ /^(?:.*\n)*?(\[.*)\z/s;
my $stanzas = eval { JSON::PP->new->utf8->decode($json_text) };
fail("pgbackrest info output is not valid JSON: " . clean($@ || '')) unless ref $stanzas;
fail("pgbackrest info output is not a list of stanzas") unless ref $stanzas eq 'ARRAY';

my $collected_at = iso($now);
my $window_start = $now - $opt{days} * 86400;
my $printed = 0;
foreach my $st (@$stanzas) {
  next unless ref $st eq 'HASH';
  my $name = defined $st->{name} ? $st->{name} : '';
  next if defined $opt{stanza} && $opt{stanza} ne '' && $name ne $opt{stanza};
  my $status = ref $st->{status} eq 'HASH' ? $st->{status} : {};
  my @backups = ref $st->{backup} eq 'ARRAY' ? grep { ref $_ eq 'HASH' } @{$st->{backup}} : ();
  my ($in_window, $full_in_window, $errors_in_window) = (0, 0, 0);
  my ($last, $last_full);
  foreach my $b (@backups) {
    my $stop = ref $b->{timestamp} eq 'HASH' ? $b->{timestamp}{stop} : undef;
    next unless defined $stop && $stop =~ /^\d+$/;
    my $type = defined $b->{type} ? $b->{type} : '';
    if ($stop >= $window_start) {
      $in_window++;
      $full_in_window++ if $type eq 'full';
      $errors_in_window++ if $b->{error};   # JSON::PP booleans are true/false in boolean context
    }
    $last = $b if !defined $last || $stop > $last->{timestamp}{stop};
    $last_full = $b if $type eq 'full' && (!defined $last_full || $stop > $last_full->{timestamp}{stop});
  }
  my @repo;
  if (ref $st->{repo} eq 'ARRAY') {
    foreach my $r (@{$st->{repo}}) {
      next unless ref $r eq 'HASH';
      my $rs = ref $r->{status} eq 'HASH' ? $r->{status} : {};
      push @repo, (defined $r->{key} ? $r->{key} : '?') . ':' . (defined $rs->{code} ? $rs->{code} : '?') . ' ' . (defined $rs->{message} ? $rs->{message} : '');
    }
  }
  my @row = (
    $name,
    defined $status->{code} ? $status->{code} : '',
    defined $status->{message} ? $status->{message} : '',
    $in_window,
    $full_in_window,
    $last ? ($last->{label} // '') : '',
    $last ? ($last->{type} // '') : '',
    $last ? iso($last->{timestamp}{stop}) : '',
    $last ? sprintf('%.1f', ($now - $last->{timestamp}{stop}) / 3600) : '',
    $last_full ? sprintf('%.1f', ($now - $last_full->{timestamp}{stop}) / 86400) : '',
    $last && defined $last->{timestamp}{start} && $last->{timestamp}{start} =~ /^\d+$/ ? $last->{timestamp}{stop} - $last->{timestamp}{start} : '',
    $last && ref $last->{info} eq 'HASH' && ref $last->{info}{repository} eq 'HASH' && defined $last->{info}{repository}{size} ? $last->{info}{repository}{size} : '',
    $errors_in_window,
    join('; ', @repo),
    $collected_at,
  );
  print 'em_result=' . join('|', map { clean($_) } @row) . "\n";
  $printed++;
}
fail(defined $opt{stanza} && $opt{stanza} ne '' ? "stanza '$opt{stanza}' not found in pgbackrest info output" : "pgbackrest info reported no stanza") unless $printed;
exit 0;

sub run_pgbackrest {
  # Console logging off and stderr at error level: a healthy run prints only the JSON, a failing one its
  # ERROR line (both ride the merged pipe below). Set on the command line so a verbose configuration file
  # cannot change that.
  my @cmd = ($opt{pgbackrest}, 'info', '--output=json', '--log-level-console=off', '--log-level-stderr=error');
  push @cmd, "--config=$opt{config}" if defined $opt{config} && $opt{config} ne '';
  push @cmd, "--repo=$opt{repo}" if defined $opt{repo} && $opt{repo} ne '';
  push @cmd, "--stanza=$opt{stanza}" if defined $opt{stanza} && $opt{stanza} ne '';
  # stderr is merged into stdout (undef error handle): reading one pipe to EOF while the child fills the
  # other would deadlock on a chatty log-level-console. On failure the first non-empty line is the message.
  my ($in, $outh);
  my $pid = eval { open3($in, $outh, undef, @cmd) };   # list form: no shell involved
  fail("cannot run '$opt{pgbackrest}': " . clean($@ || $!)) unless $pid;
  my $out;
  { local $/; $out = <$outh>; }
  waitpid($pid, 0);
  my $exit = $? >> 8;
  $out = '' unless defined $out;
  if ($exit != 0) {
    # pgbackrest's own error lines look like "ERROR: [055]: ..."; prefer one of those over earlier chatter.
    my @lines = grep { /\S/ } split(/\n/, $out);
    my ($first) = ((grep { /^\s*(ERROR|FATAL|WARN)\b/ } @lines), @lines);
    fail("pgbackrest info failed (exit $exit): " . clean($first || 'no output'));
  }
  fail("pgbackrest info printed nothing") unless $out =~ /\S/;
  return $out;
}

sub read_file {
  my ($path) = @_;
  open(my $fh, '<', $path) or fail("cannot read '$path': $!");
  local $/;
  my $text = <$fh>;
  close($fh);
  return defined $text ? $text : '';
}

sub iso {
  my ($epoch) = @_;
  return '' unless defined $epoch && $epoch =~ /^\d+$/;
  return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($epoch));
}

# One line, no pipes (the delimiter), no leading/trailing blanks.
sub clean {
  my ($v) = @_;
  $v = '' unless defined $v;
  $v =~ s/[\r\n]+/ /g;
  $v =~ s/ at \S+ line \d+\.?\s*$//;   # perl's own "at FILE line N." suffix on die messages
  $v =~ s/\|/\//g;
  $v =~ s/^\s+|\s+$//g;
  return $v;
}

sub fail {
  my ($message) = @_;
  print 'em_error=' . clean($message) . "\n";
  exit 1;
}
