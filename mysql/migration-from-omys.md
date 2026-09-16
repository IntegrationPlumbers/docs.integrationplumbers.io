---
title: Migrating from the Oracle MySQL plug-in
nav_order: 4.7
---

# Migrating from the Oracle MySQL plugin (omys) — conventions that differ

## Why this chapter exists

Both plugins monitor the same servers and many columns share names. Where the
*encoding* differs, anything ported by column name — a threshold, a BI report,
a mental baseline — keeps working syntactically and lies numerically. Every
row below was found by running the two plugins side by side against the same
instances, or during lab verification of an xmys fix.

## Measured convention differences

| Surface | omys | xmys | Porting consequence |
|---|---|---|---|
| Statement/query latency columns (`avg_latency`, `max_latency`, `total_latency`, `lock_latency`) | raw **picoseconds** (as the sys `x$` views emit) | **microseconds** (deliberate; internally exact — total/exec = avg to 3 decimals) | a threshold ported by name is off by **1e6**; re-derive from the xmys unit labels |
| Buffer-pool hit rates (`innodb_bp_hit_rate`, `innodb_bp_young_hit_rate`, `innodb_bp_not_young_hit_rate`) | raw **per-mille** (`1000 / 1000` server form; omys shows 1000 = 100%) | **percent at 1dp** (normalized in the parser; the PERCENTAGE label and the WARNING 95 / CRITICAL 90 threshold agree with the value) | an omys-derived hit-rate threshold (e.g. "alert below 950") must divide by 10; xmys ships a working LT 95/90 Condition out of the box |
| `innodb_log_capacity_used` | echoes the server's "Log capacity used" line, which always equals capacity (measured on 8.0/8.4/9.5/9.7, idle and loaded) | **derived checkpoint age** (LSN − last checkpoint) — near 0 idle, grows under write load | the xmys value is the one that answers "how much redo would crash recovery replay"; do not compare the two by name |
| Idle-server absent metrics | varies | ABSENT stays absent (em-dash / NULL), never a fabricated 0 — across parser, repository, and UI | an omys report that coalesces NULL to 0 will overstate health when pointed at xmys data; keep NULLs distinct |

## Repository representation notes (benign, verified)

- `SysStatementBy*` on EM 13.5 exposes 400 metric cells vs 425 on 24ai for
  identical data: 24ai surfaces the `db` key column as a `metric_column` row,
  13.5 does not. `key_value` is byte-identical; row counts match. Reports that
  count columns (rather than reading named ones) differ across OMS versions.

## Connection properties that keep the same syntax (deliberate)

| Surface | omys | xmys | Porting consequence |
|---|---|---|---|
| Cluster / ClusterSet `(Router) Host` and `(Router) Port` | comma lists; equal-length pairs, or one port for all hosts, or one host for all ports | **identical** (failover URL under the hood) | the old values can be re-entered as-is when the new target is registered — this is re-registration of a different plug-in's target, never an in-place upgrade of the omys target |

## Migrating with `mysql-onboard.sh`

The script ([download](https://docs.integrationplumbers.io/mysql/downloads/mysql-onboard.sh)) drives the whole migration from the OMS host with standard EM CLI. Both migrations —
Oracle `oracle.mysql.omys` → `ip.em.xmys`, and the beta `ip.em.xmyb` → `ip.em.xmys` — are re-registration of a
different plug-in's target, never an in-place upgrade: the source and the replacement coexist until you retire
the source.

1. **Export** the estate: `emcli login -username=<em user>` then
   `mysql-onboard.sh export --out inventory.csv --source omys` (or `beta`, or `all`). One row per source
   target; `new_name` is prefilled with the source name and `agent_host` with its agent.
2. **Review** the CSV. Every row that needs a decision carries a flag in `notes`; `apply` refuses the row until
   you resolve it and delete the flag:
   | Flag | Meaning | What to do |
   |---|---|---|
   | `KERBEROS: …` | the omys target set a KDC/realm; xmys reads only a `krb5.conf` | put the path to a krb5.conf on the agent host in `kerberos_config` |
   | `LICENSE: no key on source` / `LICENSE: beta key exported` | omys has no licence; a beta key is refused by GA (`Wrong Plug-in`) | paste the GA key into `license_key` |
   | `AGENT: Windows agent` | ip.em.xmys ships a Linux agent side only | set `agent_host` to a Linux agent that reaches the server. **`modify_target` cannot move a target between agents**, so if the replacement target already exists, `emcli delete_target` it first and then re-run `apply` — a re-run alone will not move it |
   | `TLS: source uses <mode>/truststore` | the source is set to `verify_ca` or `verify_identity`, or carries a truststore path — the modes and the client truststore credentials this release defers (guide [2.5](prerequisites.md#tls), 4.1) | set `use_secure` to `required` (or `disabled`) and clear `ts_dir` / `ts_type`. The exported values are left as the source had them so you can see what it did; `apply` refuses the row until the flag is gone, and refuses the values themselves in any case |
   | `STATUS: source target is Down` | informational | migrate anyway, or fix the source first |
   | `NAME: …` | informational | rename in `new_name` if you like |
   | `DRLAG: source sets dr_max_lag=<n>` | the omys ClusterSet carries a DR max tolerated GTID lag and the CSV has no column for it | informational; `apply` does not block on it. After `apply`, set **DR Max Tolerated GTID Lag (transactions)** (`ip_mysql_clusterset_dr_max_lag`) on the new ClusterSet target to the same value — through **Monitoring Configuration** ([4.5](targets-and-properties.md#modify-or-remove-a-target)) or `emcli modify_target … -properties="ip_mysql_clusterset_dr_max_lag:<n>" -on_agent`. Left alone it reverts to the shipped default and the `dr_promotion_ready` condition evaluates against that instead |
   `use_secure` accepts `disabled` and `required` only. `verify_ca` and `verify_identity` are reserved in the CSV
   schema but rejected in this release, and so is any value in the `ts_dir` / `ts_type` columns: the client
   truststore credentials those modes depend on are deferred (guide [2.5](prerequisites.md#tls), 4.1). Use `required` where you need an
   encrypted session.
   Fill `username` (or pass `--username`) and, for rows that use a different account, `password` — the
   least-privilege `em_monitoring` account and its grants are in guide [2.4](prerequisites.md#the-monitoring-user). None of `username`, `password`,
   `--username` or `$MYSQL_MON_PW` may contain `;` or `:` — `emcli`'s `-credentials` option has no separator
   override, so either character silently corrupts every row it reaches. (A later release may lift this: `emcli`
   exposes a `monitoring_creds` separator name that `add_target` may accept, which a follow-up task will
   establish; until then the refusal is the whole of the answer, and the fix is a password without those two
   characters.)
   Before `apply`, place MySQL Connector/J in `<agentStateDir>/ip_plugin/xmys/lib/` on every agent named in
   `agent_host` (guide [2.9](prerequisites.md#mysql-connectorj-on-agent-hosts)). The new targets start collecting the moment they are created, and a target created on
   an agent without the driver reports the driver message instead of data until the jar is there.
3. **Apply**: `MYSQL_MON_PW='…' mysql-onboard.sh apply --csv inventory.csv --username em_monitoring --dry-run`
   prints every `emcli add_target` it would run (passwords redacted); drop `--dry-run` to create the targets.
   Re-running is safe: existing targets get their properties re-pushed with `-on_agent`. What a re-run cannot do
   is move a target to a different agent — `modify_target` has no option for it — so a changed `agent_host` on a
   target that already exists needs `emcli delete_target -name=<new_name> -type=<target_type>` first, and then
   `apply` again. `--username USER` sets
   the default for rows whose `username` cell is empty; `--password-env VAR` (default `MYSQL_MON_PW`) supplies
   the default password the same way.
4. **Verify**: `mysql-onboard.sh verify --csv inventory.csv` waits for each target to report Up and, for
   database targets, `License` = Active, and prints a table. Fix and re-run `apply` for any FAIL row.
   `--timeout SECONDS` (default 1200) is **per target, not for the run**: the `License` metric collects every
   15 minutes, so a freshly created target can take up to a quarter of an hour to turn Active even when
   everything about it is right, and a CSV with N targets that never come Up takes up to N x timeout in total.
5. **Coexist**: leave both plug-ins monitoring for as long as your change process needs — thresholds, reports and
   habits port by the tables above, not by column name.
6. **Associate** the shipped standards: `mysql-onboard.sh associate --csv inventory.csv` (see guide [4.6](targets-and-properties.md#associate-compliance-standards) for the
   five standards; the console framework association is the alternative).
7. **Retire** the sources: `mysql-onboard.sh retire --csv inventory.csv` prints the plan; add `--yes` to run
   `emcli delete_target` for every source whose replacement verifies Up. A source whose replacement is not Up is
   never deleted.

Every mode writes a log (`--log FILE`, default `./mysql-onboard-<mode>-<time>.log`). `apply` and `associate`
print the generic summary line `SUMMARY <mode>: created=… skipped=… updated=… warned=… failed=…`; `verify` and
`retire` print their own (`SUMMARY verify: passed=N failed=M`, `SUMMARY retire: retired=N skipped=S failed=F`);
all four exit with the number of failed rows, capped at 255 (a process exit status is one byte, so an uncapped
256 failures would exit 0). Exit 2 is also the usage and validation code — a bad option, a malformed CSV, a
rejected row, an unwritable log — where nothing ran at all; the summary line, present only in the first case,
is what tells the two apart. `export` instead logs `export: <n> rows written to <file>` and exits 0 — 2 only on
a hard error such as an expired `emcli` session or an existing `--out` file without `--force`. Passwords never appear in the CSV written by `export`, in the log, or in `--dry-run` output.
`apply` writes the monitoring password to an owner-only (mode 600) temporary file for the length of each `add_target`/
`modify_target` call and passes it to `emcli` via `-input_file`, never on the command line itself; the file is removed
as soon as the call returns, with an exit trap as a backstop (EM CLI's `-input_file` option substitutes the file's
contents for a tag in `-credentials`).
One exposure remains, and it is EM CLI's, not the script's: `add_target`/`modify_target` have no file-based form for
`-properties` (same probe), so the licence key is still inline there, visible in that `emcli` process's command line
for the few seconds of each call to any other account with shell access to the OMS host — exactly as with the inline
`emcli add_target` in guide [4.3](targets-and-properties.md#add-a-target-with-em-cli). Run `apply` on a host where only administrators have shell access.

Both files the tool creates — the run log and export's `--out` CSV — are created **owner-only (mode 600)**,
because both can carry licence keys; and the `signature=` half of every licence key is masked
(`signature=<redacted>`) wherever the tool prints or logs a command or an `emcli` reply. The key itself still
reaches `emcli` intact, and the CSV keeps the real key — you have to be able to re-apply from it. A CSV
holding any non-empty `password` or `license_key` cell must be `chmod 600`: `apply` refuses to read one that
is group- or world-readable and names which kind of secret it found.

### Threshold porting worksheet

For each threshold you carry over, look the column up in "Measured convention differences" above: statement
latency columns divide by 1,000,000 (picoseconds → microseconds); buffer-pool hit rates divide by 10 (per-mille →
percent); `innodb_log_capacity_used` is a different quantity and is not ported; NULL-coalescing reports must keep
NULLs. Everything else ports by name.
