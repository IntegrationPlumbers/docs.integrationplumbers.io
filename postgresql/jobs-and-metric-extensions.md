---
title: Jobs and metric extensions
nav_order: 16
---

# Jobs and metric extensions

When you need to act on a target directly (clear a batch of idle connections, take an ad hoc backup, fail over a Patroni cluster, or collect your own custom query as a metric), the plug-in exposes that as an Enterprise Manager job type or a Metric Extension adapter rather than a button on a page.

> **Prerequisites for this page**
> - The jobs behind **Plan Analysis**, **Plan Drift Advisor**, **Workload History**, **Retention Policies**, and the **Configure auto_explain** action need [Preferred Credentials](prerequisites.md#preferred-credentials) set for the target — the plug-in submits those jobs for you, without prompting.
> - **Kill Idle PostgreSQL Connections**, **Backup Postgresql Database**, **Restore Postgresql Database**, and **Switchover PostgreSQL Cluster** are jobs you create yourself from Enterprise ▸ Job ▸ Activity, so you choose credentials in the job wizard instead.
> - Jobs run through the Enterprise Manager agent on [the agent host](prerequisites.md#agent-host); the account executing them needs the tools each job calls on its `PATH`.
> - A custom query in a Metric Extension needs [the monitoring role](prerequisites.md#monitoring-role), or another role with read access to whatever your query touches.

**Where to find it:** the jobs below run from **Enterprise ▸ Job ▸ Activity ▸ Create Job**; Metric Extensions are created from **Enterprise ▸ Monitoring ▸ Metric Extensions**.

**In this page:** Jobs shipped with the plug-in · Kill Idle PostgreSQL Connections · Backup and Restore jobs · Apply Index Recommendation · Patroni cluster switchover · Data-management jobs · Custom queries with a Metric Extension · pgBackRest backup history

## Jobs shipped with the plug-in

Every job type the plug-in ships is single-target and agent-bound — it runs against one target through the Enterprise Manager agent. Most back a console page; a few exist only for direct or scripted use.

| Job | Target type | Purpose | Used by |
|---|---|---|---|
| **PostgreSQL - Analyze Query** | PostgreSQL Database | Runs a single EXPLAIN against the target database. This is the only EXPLAIN that executes a statement, and the only place the plug-in's console runs SQL you supply; [custom-query Metric Extensions](#custom-queries-with-a-metric-extension) you define run your own SQL on their schedule. The Index Advisor's HypoPG simulation issues a plan-only `EXPLAIN (FORMAT JSON)` that executes nothing. | [Plan Drift Advisor](plan-drift-advisor.md#fix-workbench-test-a-rewrite) — Fix Workbench: Test a Rewrite; used by the console page, not normally run by hand. |
| **PostgreSQL - Read Plan Drift Data** | PostgreSQL Database | Reads the plan-drift lists, history, captured plans, baselines, audit trail, and insights from the agent-local store. | [Plan Drift Advisor](plan-drift-advisor.md) (every panel); used by the console page, not normally run by hand. |
| **PostgreSQL - Plan Drift Baseline Action** | PostgreSQL Database | Applies a baseline action (accept, pin, unpin, retire, or set the drift-detection configuration) that you submit from the page. | [Plan Drift Advisor](plan-drift-advisor.md#baseline-governance) — Baseline governance. |
| **PostgreSQL - Read Workload History Data** | PostgreSQL Database | Reads history from the agent-local store: the statement aggregates, and the vacuum, index, lock, buffer cache, parameter, and server log history. It accepts an optional **Database**, an optional **Object** (one table or index), and an optional **Event Category**, so a history chart can show any table or index. | [Workload History](workload-history.md), the history sections on [Vacuum Advisor](vacuum-advisor.md#vacuum-history), [Index Advisor](index-advisor.md#index-history), and the [Monitoring pages](monitoring-pages.md#page-layout), and the Retention Policies prefill; used by the console pages, not normally run by hand. |
| **PostgreSQL - Apply Index Recommendation** | PostgreSQL Database | Runs the `CREATE INDEX CONCURRENTLY` or `DROP INDEX CONCURRENTLY` behind one Index Advisor recommendation, after you confirm it. | [Index Advisor](index-advisor.md#apply) — Apply. See [Apply Index Recommendation](#apply-index-recommendation). |
| **PostgreSQL - Configure auto_explain** | PostgreSQL Database | Applies the plan-capture settings through `ALTER SYSTEM`. | [Monitoring Readiness](monitoring-readiness.md#configure-auto-explain) — Configure auto_explain. Also one of the seven [data-management jobs](#data-management-jobs). |
| **PostgreSQL - Set Plan Capture Window & Opt-in** | PostgreSQL Database | Sets the `log_analyze` per-target opt-in and the off-peak plan-harvest window. | [Plan Analysis](plan-analysis.md#capture-window) — Capture Window. Also one of the seven [data-management jobs](#data-management-jobs). |
| **PostgreSQL - Set Granular Retention Days** | PostgreSQL Database | Sets per-tier retention days and protected minimums for all nineteen history types. | [History store and retention](history-store-and-retention.md#retention-policies) — Retention Policies (Save). |
| **PostgreSQL - Set Plan Archive Size Ceiling** | PostgreSQL Database | Sets the whole-store MB ceiling and the plan-archive ceiling (oldest-first eviction). | [History store and retention](history-store-and-retention.md#retention-policies) — Retention Policies (Save). |
| **PostgreSQL - Reclaim Collection Store Disk Space** | PostgreSQL Database | Compacts the store file on demand and reports the space freed. | Not tied to a page — run directly or via `emcli`. |
| **PostgreSQL - Set Wait History Retention Threshold** | PostgreSQL Database | Sets the minimum estimated daily wait time below which condensed wait-event rows are dropped. | Not tied to a page — run directly or via `emcli`. |
| **PostgreSQL - Trim Historical Granular Collections** | PostgreSQL Database | Runs the daily retention, eviction, and compaction maintenance on demand. | Not tied to a page — run directly or via `emcli`. |
| **Kill Idle PostgreSQL Connections** | PostgreSQL Database | Terminates idle or idle-in-transaction PostgreSQL sessions. | Not tied to a page — create it yourself (see below). |
| **Backup Postgresql Database** | PostgreSQL Database | Runs `pg_dump` against the target database. | Not tied to a page — create it yourself (see below). |
| **Restore Postgresql Database** | PostgreSQL Database | Runs `pg_restore` (or `psql`, for a plain-text SQL dump) against the target database. | Not tied to a page — create it yourself (see below). |
| **Switchover PostgreSQL Cluster** | PostgreSQL Cluster | Initiates a Patroni-managed controlled failover to a candidate node. | The Cluster Home switchover dialog — see [Monitoring pages](monitoring-pages.md#patroni-switchover). |

## Kill Idle PostgreSQL Connections

This job terminates idle PostgreSQL connections directly from Enterprise Manager. Use it to clear stale sessions that are holding resources.

### Create the job

1. Choose **Enterprise ▸ Job ▸ Activity ▸ Create Job ▸ Kill Idle PostgreSQL Connections**.
2. Link the target to run the job against and give it a meaningful job name.
3. Configure the parameters:
   - **Database Name** — the name of the PostgreSQL database.
   - **Host/IP Address** — hostname or IP address of the PostgreSQL server.
   - **Path to pgpass file** — the absolute path to the [`.pgpass` file](https://www.postgresql.org/docs/current/libpq-pgpass.html) containing the connection credentials.
4. Configure the credentials:
   - **PostgreSQL Credentials** — the role used must have permission to terminate connections (`pg_terminate_backend`), which requires superuser privileges.
   - **Agent Host Credentials** — host credentials for the machine where the Enterprise Manager agent is installed. The user must be able to execute the job and read the `.pgpass` file.

### Notes

- The job only terminates sessions in the `idle` or `idle in transaction` states.
- Connections belonging to the user running the job, or to the PostgreSQL system process (`pg_backend_pid()`), are never terminated.
- The job must run on a local agent where `psql` is installed and on the system `PATH`.

## Backup and Restore jobs

The plug-in ships a matched pair of jobs for ad hoc backup and restore, both driven by parameters you supply at job-creation time.

### Backup Postgresql Database

Runs `pg_dump` against the target database. The connection port is filled in automatically from the target's own properties.

**Credentials**
- **PostgreSQL Credentials** — the role used to connect for the dump.
- **Agent Host Credentials** — host credentials for the machine where the agent runs the job.

**Parameters**

| Parameter | Description |
|---|---|
| Database name | Name of the database to back up. |
| Backup file path | Fully qualified path on the target host. |
| `pg_dump` flags | Flags passed to `pg_dump`, for example `-F c`. |
| Fully qualified hostname/IP address | Must be listed in the pgpass file. |
| Fully qualified path to pgpass.conf | Fully qualified path to the pgpass file. |


The job runs `pg_dump` from the PATH of the Agent Host Credentials user on the agent host; the plug-in does not ship PostgreSQL client tools, so install them there first. Both credential sets must be set for the target under Preferred Credentials before the job can run. The connection authenticates with the PostgreSQL Credentials you choose for the job; the pgpass file you name is used only when those credentials carry no password, and must then be readable by the Agent Host Credentials user. An existing file at **Backup file path** is overwritten. With the directory format (`-F d`), `pg_dump` refuses a directory that is not empty. The flags field cannot be left blank; pass at least the format, for example `-F c`. Read the job's output to confirm the result: it shows the exact command that ran and either "Successfully backed up" or the `pg_dump` error.

### Restore Postgresql Database

Runs `pg_restore` against the target database — or `psql`, if you mark the backup file as plain-text SQL.

**Credentials**
- **PostgreSQL Credentials** — the role used to connect for the restore.
- **Agent Host Credentials** — host credentials for the machine where the agent runs the job.

**Parameters**

| Parameter | Description |
|---|---|
| Database name | Name of the database to restore. |
| Backup file path | Fully qualified path on the target host. |
| `pg_restore` flags | Flags passed to `pg_restore`. If "Is the backup file plain text SQL?" is `yes`, `psql` runs instead. |
| Fully Qualified Hostname/IP Address | Must be listed in the pgpass file. |
| Fully qualified path to pgpass.conf | Fully qualified path to the pgpass file. |
| Is the backup file plain text SQL? | Optional. Type `yes` if the backup file is plain-text SQL. |


The database named in **Database name** must already exist: the job connects to it and restores into it, and does not create it. `pg_restore` and `psql` must be on the PATH of the Agent Host Credentials user, and the same two credential sets as for Backup must be set for the target. If you leave "Is the backup file plain text SQL?" empty, the job detects the format from the file itself (custom, tar, or directory dumps go to `pg_restore`; anything else is treated as plain SQL and goes to `psql`). The flags field cannot be left blank either (`--no-owner` is a safe minimum). Read the job's output to confirm the result: a `pg_restore` error such as "database … does not exist" appears there, followed by "Failed to restore".

## Apply Index Recommendation {#apply-index-recommendation}

**PostgreSQL - Apply Index Recommendation** is the job behind the **Apply** action on [Index Advisor](index-advisor.md#apply). Each run executes one statement, a `CREATE INDEX CONCURRENTLY` or a `DROP INDEX CONCURRENTLY`, and nothing else.

The job never accepts SQL text. Its parameters are the parts of one recommendation, and it rebuilds the statement from them after checking each part against the live catalog:

| Parameter | Meaning |
|---|---|
| Action | Create or drop |
| Database Name | The database the statement runs in |
| Schema | The schema of the table or index |
| Table (create) or Index (drop) | The object the statement acts on |
| Column (create) | The column to index |
| Index Method (create) | The access method, for example btree or gin |
| Operator Class (create, optional) | An operator class, where the recommendation carries one |
| Finding Category, Finding Object ID | The Index Advisor finding the run answers, so the job can confirm the finding still holds |
| Requested By | The Enterprise Manager user who clicked Apply |

It runs with the submitting user's Preferred Credentials for the target: Agent Host Credentials, and Postgresql Preferred Credentials for a role that owns the tables concerned. It never uses the monitoring credentials. See [Preferred Credentials](prerequisites.md#preferred-credentials).

Every run is recorded twice: as an Enterprise Manager job in Job Activity, with who submitted it, the statement parts, and the output, and as a row under **Apply History** on the Index Advisor page. The job is meant to be submitted from the page, which fills in the finding it answers; what it refuses, and what it does when a build or a drop is interrupted, is described under [Apply a recommendation](index-advisor.md#apply).

## Patroni cluster switchover

**Switchover PostgreSQL Cluster** runs a Patroni-managed controlled failover, promoting the non-leader cluster member you choose (or letting Patroni pick the best available standby) through the Patroni REST API. Enterprise Manager submits this job for you when you use the switchover dialog on the cluster's home page — see [Monitoring pages](monitoring-pages.md#patroni-switchover) for how to start it and what to expect.

## Data-management jobs

Seven jobs back the **Retention Policies** page and the store's daily maintenance, and are also available for direct or scripted use through `emcli`:

- **PostgreSQL - Set Granular Retention Days** — sets per-tier retention days and protected minimums for all nineteen history types, including the server log events, autovacuum log events, lock samples, buffer cache samples, and parameter changes added in 24.1.4.0.0 / 13.5.18.0.0.
- **PostgreSQL - Set Plan Archive Size Ceiling** — sets the whole-store MB ceiling and the plan-archive ceiling (oldest-first eviction).
- **PostgreSQL - Reclaim Collection Store Disk Space** — compacts the store file on demand and reports the space freed.
- **PostgreSQL - Set Wait History Retention Threshold** — sets the minimum estimated daily wait time below which condensed wait-event rows are dropped.
- **PostgreSQL - Configure auto_explain** — applies the plan-capture settings through `ALTER SYSTEM`, the same job the Monitoring Readiness **Configure auto_explain** action submits.
- **PostgreSQL - Set Plan Capture Window & Opt-in** — sets the `log_analyze` per-target opt-in and the off-peak plan-harvest window.
- **PostgreSQL - Trim Historical Granular Collections** — runs the daily retention, eviction, and compaction maintenance on demand.

For parameters, credentials, and how each maps to the Retention Policies page, see [Data-management jobs](history-store-and-retention.md#jobs).

## Custom queries with a Metric Extension

The plug-in supports Enterprise Manager's Metric Extension feature, so you can define your own metric collections from a custom query that runs against the target database. When you create the Metric Extension, select and configure an adapter of type **OS Command - Multiple Columns**.

### Configuring the "OS Command - Multiple Columns" adapter

### Basic properties

**Command:** `%perlBin%/perl`

**Script:** `<AGENT_BASE>/agent_<AGENT_VERSION>/plugins/ip.em.xpgs.agent.plugin_<PLUGIN_VERSION>/scripts/run_custom_query.pl`

Replace `<AGENT_BASE>`, `<AGENT_VERSION>`, and `<PLUGIN_VERSION>` with their actual values in the path. This path structure can vary across Enterprise Manager environments. If yours is different, search for the file `run_custom_query.pl` under your `$ORACLE_HOME` directory.

**Arguments:** Leave this field blank.

**Delimiter:** `|`

**Starts With:** `em_result=`

### Advanced properties

### Input properties

**USERNAME:** `username`

> This should be the literal string "username", not the actual username that connects to the database. In some environments this field is already present with the value "username" and should not be altered.

**PASSWORD:** `password`

> This should be the literal string "password", not the actual password that connects to the database. In some environments this field is already present with the value "password" and should not be altered.

### Environment variables

**TARGET_CONFIG:** `port=%port%,host=%host%,primarydb=%primarydb%,guid=%guid%,license=%license%,displayname=%DISPLAY_NAME%`

> Do not replace any of the variables enclosed in percent symbols with hardcoded values.

**QUERY:** Enter the custom query that you want to run against your target database. Only single-query execution is supported.

**COLUMNS:** Enter the columns to be retrieved as a comma-delimited list, with no whitespace and no quotes. The order you specify becomes the order the columns are returned in.

**PLUGIN_SCRIPTS_DIR:** `<AGENT_BASE>/agent_<AGENT_VERSION>/plugins/ip.em.xpgs.agent.plugin_<PLUGIN_VERSION>/scripts`

Replace `<AGENT_BASE>`, `<AGENT_VERSION>`, and `<PLUGIN_VERSION>` with their actual values in the path. This is the same path where you uploaded `run_custom_query.pl` when configuring Basic properties.

**LOG4J_CONFIGURATION_FILE:** This value should already be present and should not be altered.

**Upload Custom Files:** This table populates automatically once you select the script in Basic properties. If it does not populate automatically, upload the script here manually.

The remaining steps of developing the Metric Extension depend on your own custom setup. Confirm the output of your metric extension with a test execution before saving it.

## pgBackRest backup history {#pgbackrest}

If you back up with pgBackRest, you can report its backup history as an Enterprise Manager metric: per stanza, the stanza status, the backups completed in the last 30 days, the last backup and how long ago it finished, the age of the last full backup, and the backups pgBackRest flagged with errors. It is a Metric Extension you create from a script we supply, not part of the plug-in archive, so it can be added on any Enterprise Manager that has the plug-in deployed. Thresholds on it raise ordinary incidents through the notification path the target already uses.

Download the script: [pgbackrest_backup_history.pl](downloads/pgbackrest_backup_history.pl). It runs `pgbackrest info --output=json` and uses only the Perl modules shipped with the agent.

### Where it can run

The adapter runs the script on the agent monitoring the target, as the agent user. That host must have pgBackRest installed and configured for the stanza, and the agent user needs read access to the pgBackRest configuration and repository, or the `--repo-host` setup pgBackRest itself uses. A target monitored by a remote agent cannot use the script as it is: run the agent on the database or repository host, or wrap the command in an `ssh` call in your own copy of the script.

Try it on that host before creating anything:

```
perl pgbackrest_backup_history.pl                       # every stanza
perl pgbackrest_backup_history.pl --stanza=demo         # one stanza
perl pgbackrest_backup_history.pl --config=/etc/pgbackrest/pgbackrest.conf --repo=2
```

Each stanza prints one line starting `em_result=`. Without usable output (pgBackRest not installed or not on the path, a non-zero exit, unreadable JSON, a stanza that does not exist) the script prints one `em_error=` line and exits 1, so the metric shows a collection error and not an all-clear.

### Columns

Pipe-delimited, in this order:

| # | Column | Type | Key | Meaning |
|---|---|---|---|---|
| 1 | `stanza` | String | Yes | The pgBackRest stanza. |
| 2 | `status_code` | Number | | pgBackRest's stanza status: 0 ok, 1 missing stanza path, 2 no valid backups, 3 missing stanza data, 4 backup or expire running, 99 other. |
| 3 | `status_message` | String | | pgBackRest's status text. |
| 4 | `backups_30d` | Number | | Completed backups of any type that finished in the window (`--days`, default 30). |
| 5 | `full_backups_30d` | Number | | Completed full backups in the window. |
| 6 | `last_backup_label` | String | | Label of the most recently finished backup. |
| 7 | `last_backup_type` | String | | full, diff, or incr. |
| 8 | `last_backup_finished_at` | String | | When it finished, UTC. |
| 9 | `hours_since_last_backup` | Number | | Hours since the last completed backup: the main threshold value. Empty when there is none; threshold `status_code` for that case. |
| 10 | `last_full_backup_age_days` | Number | | Days since the last full backup finished. |
| 11 | `last_backup_duration_seconds` | Number | | How long the last backup took. |
| 12 | `last_backup_repo_size_bytes` | Number | | Its size in the repository. Compressed; a diff or incr holds only what changed. |
| 13 | `backups_with_errors_30d` | Number | | Backups in the window that pgBackRest flagged with errors: page checksum errors were found while backing up. The backup completed; the data has a problem. |
| 14 | `repo_status` | String | | `<repository key>:<code> <message>` for each repository. |
| 15 | `collected_at` | String | | When the script ran, UTC. |

`pgbackrest info` lists completed backups only; a backup that fails leaves no entry. A failing schedule therefore shows as `hours_since_last_backup` growing past the schedule interval, and a broken repository or stanza as a non-zero `status_code`. Those two are the thresholds to set.

### Create the Metric Extension

In Enterprise Manager, go to **Enterprise ▸ Monitoring ▸ Metric Extensions ▸ Create ▸ Metric Extension**.

1. **General properties.** Target type **PostgreSQL Database**. Name `pgbackrest_backup_history`, display name `pgBackRest Backup History`. Adapter **OS Command - Multiple Columns**. Collection schedule: enabled, every 60 minutes.
2. **Adapter.** Command: `%perlBin%/perl`. Script: upload `pgbackrest_backup_history.pl`; the Script field then reads `%scriptsDir%/pgbackrest_backup_history.pl`. Arguments: empty for every stanza, or `--stanza=<name>`, `--config=<path>`, `--repo=<n>` as needed. Delimiter: `|`. Starts with: `em_result=`. Leave the credentials section empty: the script needs no database credentials and runs as the agent user.
3. **Columns.** Add the fifteen columns in the order of the table above, with `stanza` as the key column and the types shown. For the threshold columns set the comparison operator to `>=`.
4. **Thresholds.** Suggested for a daily schedule: `hours_since_last_backup` Warning 26, Critical 50 (one missed run, two missed runs), and `status_code` Warning 1. Status code 4 is reported while a backup or expire is running, so a threshold on `status_code` warns during every backup unless the collection avoids the backup window or the occurrence count is set above one. Optionally, `last_full_backup_age_days` Warning 8 for a weekly full. Leave the others without thresholds.
5. **Test.** Add a target and run the test. The result shows one row per stanza. On a host without pgBackRest the test shows the `em_error` text; that is the script reporting it, not an adapter problem.
6. **Save as deployable draft**, deploy to the target to check the collection, then **publish** and deploy to the targets or groups that use pgBackRest.

The draft is created in the console. EM CLI then publishes, deploys, exports, and imports it:

```
emcli publish_metric_extension -target_type=ip_postgresql_db -name=pgbackrest_backup_history -version=1
emcli deploy_metric_extension -target_type=ip_postgresql_db -name=pgbackrest_backup_history -version=1 -target_names="PostgreSQL DB 1"
emcli export_metric_extension -target_type=ip_postgresql_db -name=pgbackrest_backup_history -version=1 -file_name=pgbackrest_backup_history_v1.zip
emcli import_metric_extension -file_name=pgbackrest_backup_history_v1.zip -rep_file_name=pgbackrest_backup_history_v1
```

Keep the exported archive: it is the importable form of this Metric Extension for your other Enterprise Manager installations.

## Related

- [History store and retention](history-store-and-retention.md#jobs) — parameters and credentials for the seven data-management jobs
- [History store and retention](history-store-and-retention.md#retention-policies) — the Retention Policies page that two of these jobs save from
- [Monitoring Readiness](monitoring-readiness.md#configure-auto-explain) — where the Configure auto_explain action runs from
- [Plan Analysis](plan-analysis.md#capture-window) — where the Capture Window setting runs from
- [Plan Drift Advisor](plan-drift-advisor.md) — where Read Plan Drift Data, Plan Drift Baseline Action, and Fix Workbench's EXPLAIN run from
- [Workload History](workload-history.md) — where Read Workload History Data runs from
- [Index Advisor](index-advisor.md#apply) — the Apply action that submits Apply Index Recommendation
- [Monitoring pages](monitoring-pages.md#patroni-switchover) — the Cluster Home switchover dialog
- [Prerequisites](prerequisites.md#preferred-credentials) — Preferred Credentials required by the automatic jobs
