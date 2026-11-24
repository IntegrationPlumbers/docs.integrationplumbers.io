---
title: Enabling the log-enhanced features
nav_order: 8
---

# Enabling the log-enhanced features

The plug-in monitors every target from catalog data alone. A set of features also reads the PostgreSQL server log, through the database connection the target already has: no agent on the database host and no operating-system access. This page lists what those features need on the monitored server, gives you a script that checks it and a script that grants it, and shows how to confirm the result.

| Feature | Where it shows |
|---|---|
| Autovacuum run history, skipped and cancelled vacuums, multi-pass index phases | [Vacuum Advisor](vacuum-advisor.md#autovacuum-activity), **Autovacuum Activity from the Server Log** |
| Dead rows held back and space never released, measured by `pgstattuple` when it is installed | [Vacuum Advisor](vacuum-advisor.md#bloat-and-dead-rows), **Bloat and Dead Rows from the Server Log** |
| Server log events sorted into categories (deadlocks, timeouts, refused connections, temporary files, slow statements, wraparound warnings, crashes, replication, and more) | [Logs](monitoring-pages.md#logs), **Events from the Server Log** and **Recent Events**; the **Server Log Events** metric |
| Captured execution plans and plan drift from `auto_explain` | [Plan Analysis](plan-analysis.md), [Plan Drift Advisor](plan-drift-advisor.md) |

Until the grants below are in place these sections stay inactive and say which grant is missing. Nothing errors, and the rest of the plug-in is unaffected.

**Where to find it:** the role, grant, extension, and `auto_explain` checks are shown live on each target's [Monitoring Readiness](monitoring-readiness.md) page. The server logging settings are reported by the check script below and by each section's own status line.

**In this page:** The scripts · The monitoring role · Read access to the server log · A readable log file · Autovacuum logging · Log line prefix · Plan capture · Optional extensions · More event categories · Patroni-managed clusters · Verifying

## The scripts {#scripts}

| File | Purpose |
|---|---|
| [check_log_enhanced_features.sql](downloads/check_log_enhanced_features.sql) | A read-only report of every item on this page for one database and one role. Run it first, and again after each change. |
| [enable_log_enhanced_features.sql](downloads/enable_log_enhanced_features.sql) | The grants. Safe to run more than once. |
| [enable_log_enhanced_features.sh](downloads/enable_log_enhanced_features.sh) | A wrapper that runs the grant script in every database the plug-in monitors. `--dry-run` shows the result and rolls back. Keep it in the same folder as the `.sql` file. |
| [recommended_logging_settings.sql](downloads/recommended_logging_settings.sql) | The optional server logging settings, as `ALTER SYSTEM` statements to review before you run them. |

The scripts need `psql` 11 or later and a superuser login to the monitored server. The plug-in never runs them and never applies a grant for you.

## 1. The monitoring role {#monitoring-role}

Required for every feature. This is the role named in the target's monitoring credentials. It needs `LOGIN` and membership of `pg_monitor`, the standard PostgreSQL monitoring role. It does not need to be a superuser.

```sql
CREATE ROLE "<monitoring role>" LOGIN PASSWORD '...';   -- if it does not exist yet
GRANT pg_monitor TO "<monitoring role>";
```

See [The monitoring role](prerequisites.md#monitoring-role).

## 2. Read access to the server log {#log-read-access}

Required for every feature on this page. The role can read the log by either of two routes, and the plug-in uses whichever it finds, preferring the first.

**The `xpgs_monitor` reader (recommended).** The grant script installs three functions in a schema named `xpgs_monitor`: `current_log_file`, `log_file_size`, and `log_read`. They are owned by the superuser who runs the script and run with that owner's rights (`SECURITY DEFINER`). They accept only a file that sits directly in the server's `log_directory`, which means the current log and its rotated siblings, and refuse anything else. The role can read the server log and nothing else on the host.

The functions and the role's EXECUTE on them are per database. Run the script while connected to each database the plug-in monitors: the target's connection database at least, and every database you add a target for.

```bash
psql -h db.example.com -d appdb -U postgres -v role=<monitoring role> -f enable_log_enhanced_features.sql
```

To cover every database in one run, or to preview the result first:

```bash
./enable_log_enhanced_features.sh --role <monitoring role> -- -h db.example.com -U postgres
./enable_log_enhanced_features.sh --role <monitoring role> --dry-run -- -h db.example.com -U postgres
```

**The built-in functions.** EXECUTE on `pg_current_logfile()`, `pg_current_logfile(text)`, `pg_stat_file(text)`, and `pg_read_file(text, bigint, bigint)`, granted in each monitored database. This is the route earlier releases documented. It still works, and the plug-in falls back to it when the `xpgs_monitor` reader is absent. Those built-ins let the role read any file inside the data and log directories, including `pg_hba.conf` and the table files of every database, which is why the grant script does not grant them.

```sql
GRANT EXECUTE ON FUNCTION pg_current_logfile(), pg_current_logfile(text), pg_stat_file(text), pg_read_file(text, bigint, bigint) TO "<monitoring role>";
```

The role does not need `pg_read_server_files` on either route, and the plug-in never asks for it. The **Server log read grants** item on **Monitoring Readiness** reports which route a target uses: `granted (xpgs_monitor log reader)` or `granted (built-in functions)`. Whichever route it uses, the plug-in itself reads only the current log file, plus the one it replaced after a rotation.

If you set a target up on the built-in functions and now want the narrower reader, run the grant script, confirm that **Monitoring Readiness** reports the `xpgs_monitor` reader, then revoke EXECUTE on the four built-ins from the role.

## 3. A readable log file {#readable-log-file}

- `logging_collector = on`, with `stderr` or `jsonlog` in `log_destination`. The vacuum history and the Logs page events read either format; `jsonlog` needs PostgreSQL 15 or later. Plan capture reads the stderr log only, so a server that writes only `jsonlog` gets the vacuum history and the event categories but no captured plans. A server that logs only `csvlog` is not read. With several destinations the plug-in prefers `stderr`, then `jsonlog`.
- `lc_messages` set to `C` or an English locale. The vacuum history recognises English messages. The event categories also use the SQLSTATE when the prefix carries it (see [Log line prefix](#log-line-prefix)), whatever the language.
- The target's optional **Path to postgres log file** property is not used by any feature on this page. It feeds only the two sections at the bottom of the Logs page, **Log Statistics** and **PostgreSQL Logs**. See [Logs](monitoring-pages.md#logs).

## 4. Autovacuum logging {#autovacuum-logging}

Needed for the vacuum history and the dead-row and bloat findings. `log_autovacuum_min_duration = 0` records every run. The default (`-1` on PostgreSQL 14, `10min` from PostgreSQL 15) records none, or only the long ones, and the Vacuum Advisor says so in the section's status line.

## 5. Log line prefix {#log-line-prefix}

Recommended. Keep `%m` and `[%p]`. Add `%u@%d` so events carry the user and database, and `%e` so events are sorted by SQLSTATE:

```
log_line_prefix = '%m [%p] %q%u@%d %e '
```

Any prefix works: the plug-in reads the server's own `log_line_prefix` and parses each line with it. Change the prefix only if nothing else parses your log by its current layout.

Two things only the prefix can supply:

- **The database of a log event.** With `%u@%d` in the prefix, the **Database** selector on the Logs page can scope **Recent Events** to one database.
- **The database of a captured plan.** `auto_explain` plans take their database from the `%u@%d` token, which must have a space on each side. Without it every captured plan is still stored and analysed, but it is not attributed to a database: **Plan Analysis** and the **Plan Drift Advisor** list it under every database of the target with its database shown as "unknown". On the PostgreSQL default prefix, `'%m [%p] '`, the **Database in log_line_prefix (%u@%d)** item on **Monitoring Readiness** shows **Attention** until the token is added. Plans captured before the change keep their blank database.

`log_line_prefix` is reloadable. After changing it, run `SELECT pg_reload_conf();`.

## 6. Plan capture {#plan-capture}

Optional. Load `auto_explain`, then use the **Configure auto_explain** action on **Monitoring Readiness**, which sets `auto_explain.log_min_duration`, `log_format = json`, `log_analyze = on`, and `log_verbose = on`. `compute_query_id = on` (or `auto` with `pg_stat_statements` loaded) matches captured plans to statements. See [Plan capture (auto_explain)](prerequisites.md#auto-explain) and [Configure auto_explain](monitoring-readiness.md#configure-auto-explain).

## 7. Optional extensions {#optional-extensions}

Each one switches a feature on when it is installed in the monitored database. An absent extension is reported, never an error.

| Extension | Enables | Needs preloading |
|---|---|---|
| `pg_stat_statements` | Statement monitoring and Workload History (required for those pages) | Yes |
| `pgstattuple` | Measured free space on the Vacuum Advisor's bloat findings; the estimate from the log is used otherwise | No |
| `pg_buffercache` | The **Buffer Cache** section on the Database page and the **Buffer Cache** metric | No |
| `pg_qualstats` | Predicate-based index recommendations | Yes |
| `hypopg` | What-If index simulations | No |
| `pg_wait_sampling` | Wait-event history | Yes |

See [Optional extensions](prerequisites.md#optional-extensions) for packages and install statements.

## 8. More event categories {#more-event-categories}

Optional. These settings decide what the server writes, so they decide which categories on the Logs page can ever fill. All are off by default except checkpoints, which are on from PostgreSQL 15.

| Setting | Category it fills |
|---|---|
| `log_min_duration_statement` (for example `1s`) | Slow statements |
| `log_temp_files` (for example `10MB`) | Temporary files |
| `log_lock_waits = on` | Lock waits |
| `log_connections = on` | Connections and disconnections. High volume on busy servers |
| `log_checkpoints = on` | Checkpoints and too-frequent-checkpoint warnings |

[recommended_logging_settings.sql](downloads/recommended_logging_settings.sql) holds the settings from sections 4, 5, and 8 as `ALTER SYSTEM` statements. Every line changes what your server writes to its log, so review each one before you run the file.

## Patroni-managed clusters {#patroni}

Patroni owns `postgresql.conf` and overrides `ALTER SYSTEM` values at the next restart. Put the settings in the DCS so every member gets them:

```
patronictl -c /etc/patroni/patroni.yml edit-config \
  -s postgresql.parameters.log_autovacuum_min_duration=0 \
  -s 'postgresql.parameters.log_line_prefix="%m [%p] %q%u@%d %e "' --force
```

The prefix value is quoted twice on purpose. `patronictl` reads the value as YAML, where an unquoted `%` starts a directive and a trailing space would be dropped.

The grants in sections 1 and 2 are ordinary SQL and replicate to the standbys on their own. Only the leader runs autovacuum, so a standby target shows zero autovacuum runs; its log is still read for events.

## Verifying {#verifying}

1. Run the check script against each monitored database. It should report no `ACTION` rows.

   ```bash
   psql -d <database> -v role=<monitoring role> -f check_log_enhanced_features.sql
   ```

2. Open the target's **Monitoring Readiness** page. The **Monitoring role (pg_monitor)** and **Server log read grants** items are green.
3. Within 15 minutes, the Vacuum Advisor's two server-log sections and the Logs page's two event sections show a green status line. Within 30 minutes, the **Server Log Events** metric lists every category under **Monitoring → All Metrics**.

## Related

- [Prerequisites](prerequisites.md#log-read-grant) — the full setup list, including the server log read grant
- [Monitoring Readiness](monitoring-readiness.md) — the live check of the role, the grant, and the extensions
- [Vacuum Advisor](vacuum-advisor.md#autovacuum-activity) — the vacuum history and bloat findings read from the log
- [Monitoring pages](monitoring-pages.md#logs) — the Logs page and its event categories
- [Troubleshooting](troubleshooting.md#log-sections-inactive) — when a server-log section stays inactive
