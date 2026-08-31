---
title: Backup monitoring
nav_order: 11
---

# Backup Monitoring (MEB / XtraBackup)

The plugin reports backup age and failure status from MySQL Enterprise Backup (MEB)
history and Percona XtraBackup (PXB) history, so a DBA can see backup health from
Enterprise Manager instead of checking cron logs by hand. Visibility depends on the
tool-side flags the customer sets up: a tool that leaves no server-side history behind
is reported as **not detected** rather than as an error. That's the first thing to
check when backup monitoring shows nothing.

## Monitoring-user grants

The plugin's monitoring user (`em_monitoring`) only ever reads history, never runs a
backup. Already covered by the global `SELECT` grant set up in
[the deployment guide](deploy-guide.md) (`GRANT SELECT, PROCESS, REPLICATION CLIENT ON
*.*`); only relevant if your policy scopes `SELECT` to named schemas instead of
granting it globally, in which case add:

```sql
GRANT SELECT ON mysql.backup_history TO 'em_monitoring'@'%';       -- MEB visibility
GRANT SELECT ON PERCONA_SCHEMA.* TO 'em_monitoring'@'%';           -- XtraBackup visibility
```

With the recommended global `SELECT` grant there is no missing-grant case to chase.
What is certified is the absent-tool path: a server with no history table for a tool
is reported as that tool **not detected**, with no alert raised. That is deliberate —
a shop that only does logical dumps must not see a false "no backups" alarm. If your
policy uses the scoped grant set above instead of the global one, detection needs read
access to those two history tables.

**Cluster targets need the same grant on the CLUSTER credential.** The
`ip_mysql_cluster` target's backup-source health metric (`BackupSource`)
reads the same two history tables under the cluster monitoring credential —
which may be provisioned separately from the database targets' user. Give
that credential the same global `SELECT` grant as the database credential; a
cluster credential without it is not a certified configuration.

## Tool visibility requirements

- **MEB logs to `mysql.backup_history` by default.** History logging is *disabled*
  with `--no-history-logging` — there is no `--backup-history` flag; MEB does not
  recognize it and errors if you pass it. If MEB backups aren't showing up, check
  whether `--no-history-logging` is set anywhere in the backup job, not for a flag
  that needs adding.
- **PXB records history only when invoked with `--history`.** Without that flag on
  the backup command, there is no server-side trace at all — nothing for the plugin
  to read, regardless of grants.
- **Logical dumps (`mysqldump`, `mysqlpump`, MySQL Shell) and storage/array snapshots
  leave no server-side record.** No SQL-only collector — this plugin included — can
  see them. If that's the only backup method in use, the plugin correctly shows
  nothing rather than a false alarm; it is not a gap to work around.

## MEB backup-user grants

The account MEB itself connects as to *run* a backup is a separate user from
`em_monitoring`, and needs a much wider grant set:

```sql
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT, CREATE, INSERT, DROP, UPDATE,
      SELECT, ALTER, CREATE TABLESPACE, FILE,
      BACKUP_ADMIN, SESSION_VARIABLES_ADMIN, ENCRYPTION_KEY_ADMIN
  ON *.* TO 'meb_backup'@'localhost';
```

`SESSION_VARIABLES_ADMIN` is **mandatory**, not optional hardening — MEB issues
`SET SQL_LOG_BIN=OFF` at connection init and fails immediately without it. Adding
`SYSTEM_VARIABLES_ADMIN` on top is optional; it only suppresses a harmless
`log_error_suppression_list` warning.

## The `@'localhost'` shadowing trap

MySQL resolves the *most specific* matching account for a connection, and an
anonymous `''@'localhost'` account — still shipped by some installations as a legacy
default, or present deliberately as a test fixture — is more specific than a named
user connecting the same way. If one exists, it **shadows** a named backup user on
socket/localhost connections: the named user's grants are silently ignored and the
anonymous account's (usually minimal) privileges apply instead, so the backup fails
in ways that look like a grant problem but aren't. Create the backup user explicitly
`@'localhost'` (as above) so it wins the match, and check for a stray anonymous
account (`SELECT user, host FROM mysql.user WHERE user = ''`) if a correctly-granted
user still can't connect over the socket.

## Cluster pattern

Back up on one cluster member; monitor any member — history rows replicate like any
other table write. **Verified on InnoDB Cluster / Group Replication**, including MEB's
`SET SQL_LOG_BIN=OFF` backups, which still replicated as expected. This is **not**
verified on classic asynchronous replication, where `SQL_LOG_BIN=OFF` semantics
differ — on async replication, monitor the server that actually runs the backups,
not an arbitrary replica.

## Alerts

Three thresholds, evaluated only when a history source is present (silence when no
tool is detected is the correct, deliberate default):

| Condition | Warning | Critical |
|---|---|---|
| Hours since last successful backup | > 26 | > 50 |
| Most recent backup failed | — | immediate |
| No backup has ever succeeded | — | immediate |

The age threshold assumes a daily backup cadence: one missed backup warns, two go
critical.

**In PXB-only environments, a failed backup writes no history row at all** — there is
nothing for the failure alert to see. In that case backup **age** is the only failure
signal; the failure alert can never fire on XtraBackup alone. MEB does write a row on
failure, so the failure alert works normally in MEB environments. A site running PXB
only should treat the age threshold as the real safety net, not the failure alert.

The age threshold only *arms* once a successful backup has been recorded — it is
computed from `MAX(end_time)` over successful rows only, so a source with history
enabled but no recorded success (a fresh `--history` table, or one whose rows were
purged) leaves `hours_since_last_success` empty and the age alert silent. This used to
be a real gap for a PXB-only site (PXB writes no row on failure either, so neither
threshold could ever fire — no alert of any kind, indefinitely). The `never_succeeded`
Condition closes it: it goes CRITICAL when a history source is present and recording,
but not one backup on record has ever succeeded — a distinct, more urgent situation
than "backups are late," worth its own alert rather than an inferred age.

`never_succeeded` only fires on a **confirmed** zero — the hours-since-success query
ran cleanly and came back with no successful row. If the query cannot run at all (for
example a column missing on an older tool build), the plugin does not know whether a
successful backup exists, so `never_succeeded` stays silent rather than guessing. The
tell for that case is `pxb_history_enabled=1` (or `meb_present=1`) with both
`hours_since_last_success` and `never_succeeded` blank.
