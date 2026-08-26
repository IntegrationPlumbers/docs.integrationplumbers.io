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

**In this page:** Jobs shipped with the plug-in · Kill Idle PostgreSQL Connections · Backup and Restore jobs · Patroni cluster switchover · Data-management jobs · Custom queries with a Metric Extension

## Jobs shipped with the plug-in

Every job type the plug-in ships is single-target and agent-bound — it runs against one target through the Enterprise Manager agent. Most back a console page; a few exist only for direct or scripted use.

| Job | Target type | Purpose | Used by |
|---|---|---|---|
| **PostgreSQL - Analyze Query** | PostgreSQL Database | Runs a single EXPLAIN against the target database. This is the only EXPLAIN that executes a statement, and the only place the plug-in's console runs SQL you supply; [custom-query Metric Extensions](#custom-queries-with-a-metric-extension) you define run your own SQL on their schedule. The Index Advisor's HypoPG simulation issues a plan-only `EXPLAIN (FORMAT JSON)` that executes nothing. | [Plan Drift Advisor](plan-drift-advisor.md#fix-workbench-test-a-rewrite) — Fix Workbench: Test a Rewrite; used by the console page, not normally run by hand. |
| **PostgreSQL - Read Plan Drift Data** | PostgreSQL Database | Reads the plan-drift lists, history, captured plans, baselines, audit trail, and insights from the agent-local store. | [Plan Drift Advisor](plan-drift-advisor.md) (every panel); used by the console page, not normally run by hand. |
| **PostgreSQL - Plan Drift Baseline Action** | PostgreSQL Database | Applies a baseline action (accept, pin, unpin, retire, or set the drift-detection configuration) that you submit from the page. | [Plan Drift Advisor](plan-drift-advisor.md#baseline-governance) — Baseline governance. |
| **PostgreSQL - Read Workload History Data** | PostgreSQL Database | Reads the database, statement, and time-series aggregates computed over the stored per-statement history. | [Workload History](workload-history.md), and the Retention Policies prefill; used by the console pages, not normally run by hand. |
| **PostgreSQL - Configure auto_explain** | PostgreSQL Database | Applies the plan-capture settings through `ALTER SYSTEM`. | [Monitoring Readiness](monitoring-readiness.md#configure-auto-explain) — Configure auto_explain. Also one of the seven [data-management jobs](#data-management-jobs). |
| **PostgreSQL - Set Plan Capture Window & Opt-in** | PostgreSQL Database | Sets the `log_analyze` per-target opt-in and the off-peak plan-harvest window. | [Plan Analysis](plan-analysis.md#capture-window) — Capture Window. Also one of the seven [data-management jobs](#data-management-jobs). |
| **PostgreSQL - Set Granular Retention Days** | PostgreSQL Database | Sets per-tier retention days and protected minimums for all twelve history types. | [History store and retention](history-store-and-retention.md#retention-policies) — Retention Policies (Save). |
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


The job runs `pg_dump` from the PATH of the Agent Host Credentials user on the agent host; the plug-in does not ship PostgreSQL client tools, so install them there first. An existing file at **Backup file path** is overwritten. With the directory format (`-F d`), `pg_dump` refuses a directory that is not empty. The password comes from the pgpass file you name; the job points `PGPASSFILE` at it.

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


The database named in **Database name** must already exist: the job connects to it and restores into it, and does not create it. `pg_restore` and `psql` must be on the PATH of the Agent Host Credentials user. If you leave "Is the backup file plain text SQL?" empty, the job detects the format from the file itself (custom, tar, or directory dumps go to `pg_restore`; anything else is treated as plain SQL and goes to `psql`).

## Patroni cluster switchover

**Switchover PostgreSQL Cluster** runs a Patroni-managed controlled failover, promoting the non-leader cluster member you choose (or letting Patroni pick the best available standby) through the Patroni REST API. Enterprise Manager submits this job for you when you use the switchover dialog on the cluster's home page — see [Monitoring pages](monitoring-pages.md#patroni-switchover) for how to start it and what to expect.

## Data-management jobs

Seven jobs back the **Retention Policies** page and the store's daily maintenance, and are also available for direct or scripted use through `emcli`:

- **PostgreSQL - Set Granular Retention Days** — sets per-tier retention days and protected minimums for all twelve history types.
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

## Related

- [History store and retention](history-store-and-retention.md#jobs) — parameters and credentials for the seven data-management jobs
- [History store and retention](history-store-and-retention.md#retention-policies) — the Retention Policies page that two of these jobs save from
- [Monitoring Readiness](monitoring-readiness.md#configure-auto-explain) — where the Configure auto_explain action runs from
- [Plan Analysis](plan-analysis.md#capture-window) — where the Capture Window setting runs from
- [Plan Drift Advisor](plan-drift-advisor.md) — where Read Plan Drift Data, Plan Drift Baseline Action, and Fix Workbench's EXPLAIN run from
- [Workload History](workload-history.md) — where Read Workload History Data runs from
- [Monitoring pages](monitoring-pages.md#patroni-switchover) — the Cluster Home switchover dialog
- [Prerequisites](prerequisites.md#preferred-credentials) — Preferred Credentials required by the automatic jobs
