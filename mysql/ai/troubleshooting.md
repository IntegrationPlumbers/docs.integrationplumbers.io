# MySQL plug-in for Oracle Enterprise Manager: AI troubleshooting guide

This file is written to be loaded into an AI assistant, and to be read by a database administrator. It is self-contained: the assistant needs no other document to use it.

## How to use this file

**What the plug-in is.** The MySQL plug-in for Oracle Enterprise Manager, made by Integration Plumbers, monitors MySQL from an Enterprise Manager management agent. The agent connects to MySQL over JDBC with an ordinary read-only account and runs every collection. Nothing is installed on the database host.

**The three target types.**

| Target type | What it represents |
|---|---|
| MySQL Database | One MySQL server instance, standalone or a member of a cluster |
| MySQL Cluster | One InnoDB Cluster, or the Group Replication group behind it, as a whole |
| MySQL ClusterSet | One InnoDB ClusterSet: a primary cluster, its replica clusters and the replication between them |

**The Monitoring Readiness page.** The console has a Monitoring Readiness page for MySQL Database targets and for MySQL ClusterSet targets. It runs read-only checks under the target's monitoring credentials when it opens and each time you choose Refresh. For each check it shows a status, the current value, the required value and a detail text. The detail text can include a SQL statement to run. The page never runs a statement itself.

**To use this file with the page.**

1. Open the target's Monitoring Readiness page and choose Refresh.
2. Copy every check that is not OK: its panel name, label, status, current value, required value and detail text.
3. Give this file and those results to your assistant, with the MySQL server version and the Enterprise Manager version.
4. Find each check below by its section id and item id, which are in the headings.

**Every statement in this file is for an administrator to review and run.** The plug-in changes nothing on the server. The monitoring account has no write privilege, so a fix statement fails if you run it as that account. Run it as an account with the privilege the statement needs, after checking it against your own change process.

**Remove secrets before you share anything.** Passwords and licence keys must not appear in text you send to an assistant or to support. The plug-in removes passwords it knows about from the page text, but check the text yourself.

## Status words

The collector emits one of four statuses per check. The page shows them with these words.

| Collector status | Page word | Meaning |
|---|---|---|
| `ok` | OK | The check ran and the requirement is met. |
| `warn` | Attention | The feature works but something is missing or limited, or an optional check is not met. |
| `fail` | Not functional | A required check ran and failed. The pages that depend on it are empty or wrong. |
| `unknown` | Unknown | The check did not run or could not decide. Unknown means not checked. It is never a pass. |

Each check is either required or optional. An optional check that fails counts as Attention, never Not functional. A panel shows the worst status of its checks, in the order Not functional, Attention, Unknown, OK. The line above the panels says all features are ready only when every panel is OK.

## When the page shows nothing was verified

The page shows one of three Unknown states for the whole page when it has no check results. In each, nothing was verified, and no check is reported as ready.

| What the page says | Meaning | What to do |
|---|---|---|
| "The readiness check could not be read, so nothing was verified. Check that the target is up and its agent is reachable, then press Refresh." | The read failed. | Check that the target is Up and that its agent is running and reachable from the OMS (`emctl status agent` on the agent host). Choose Refresh. |
| "The readiness check did not answer within 30 seconds, so nothing was verified. The agent may be busy or unreachable. Press Refresh to try again." | The read timed out after 30 seconds. | Check that the agent is not overloaded. See the sizing rule in the Prerequisites chapter of the user guide. Choose Refresh. |
| "The readiness check returned no results, so nothing was verified. The usual cause is that the MySQL Connector/J driver is not installed on the agent host; see the prerequisites in the user guide. Press Refresh to try again." | The check ran and returned no rows. | Check that exactly one `mysql-connector-j-*.jar` is in the agent's plug-in driver directory. See "MySQL Connector/J not found" below. |

## Readiness checks

The checks below are the complete set the collector emits. A MySQL Database target emits sections `connection`, `performance_schema`, `sys_schema`, `backup` and `license`. A MySQL ClusterSet target emits sections `connection` and `mysql_shell`. A MySQL Cluster target has no Monitoring Readiness page.

Each check is a row with a section id and an item id. The privilege checks are in section `connection`, shown in the panel Connection and privileges.

| Panel (section id) | Check label (item id) | Required | Applies to |
|---|---|---|---|
| Connection and privileges (`connection`) | Database connection (`database_connection`) | yes | Database, ClusterSet |
| Connection and privileges (`connection`) | PROCESS privilege (`process_priv`) | yes | Database |
| Connection and privileges (`connection`) | REPLICATION CLIENT privilege (`replication_client_priv`) | yes | Database |
| Connection and privileges (`connection`) | Read access to performance_schema (`select_perf_schema`) | yes | Database |
| performance_schema (`performance_schema`) | performance_schema enabled (`enabled`) | yes | Database |
| performance_schema (`performance_schema`) | Statement digest consumers (`statements_digest_consumer`) | yes | Database |
| performance_schema (`performance_schema`) | Statement instruments (`statement_instruments`) | yes | Database |
| performance_schema (`performance_schema`) | Wait instruments (`wait_instruments`) | optional | Database |
| performance_schema (`performance_schema`) | Memory instruments (`memory_instruments`) | optional | Database |
| sys schema (`sys_schema`) | sys schema installed (`installed`) | yes | Database |
| Backup tool (`backup`) | Backup tool history (`backup_tool`) | optional | Database |
| Plug-in license (`license`) | Plug-in licence (`license_active`) | yes | Database |
| MySQL Shell (`mysql_shell`) | MySQL Shell (mysqlsh) on the agent host (`mysqlsh_installed`) | optional | ClusterSet |
| MySQL Shell (`mysql_shell`) | ClusterSet AdminAPI connection shape (`adminapi_connection_shape`) | optional | ClusterSet |

### How to read an Unknown reason

An Unknown check puts its reason in the Current column. These are the reasons the collector uses.

| Current value | Meaning |
|---|---|
| `not checked: connection failed` | The database connection failed, so every check that needs it was not run. Fix the connection first. |
| `not checked: performance_schema is OFF` | `performance_schema` is off, so the consumer and instrument checks cannot be read. Fix `performance_schema enabled` first. |
| `not checked: probe did not run` | The collector did not run that probe. Choose Refresh. If it repeats, send the page results to support. |
| `not checked: <reason>` | A privilege probe was not run and gave its reason. |
| `undetermined: <message>` | The probe ran and failed for a reason other than a missing privilege or object. The message is the server's, on one line, cut to 200 characters. Read it as the evidence. |
| `undetermined: ...` followed by a fixed sentence | The probe ran and returned something the check cannot decide on. Each such sentence is listed under the check it belongs to. |

### Section `connection`, item `database_connection`: Database connection

- **Required value:** connect with the monitoring credentials.
- **Status rules:** `ok` when the connection succeeds; `fail` when it does not.
- **Symptom, OK:** the Current column reads `connected as <account>, MySQL <version>, <transport>`. The transport reads like `TCP, TLS required`, `TCP, TLS off`, `Unix socket, TLS off` or `TCP, Kerberos, TLS off`.
- **Symptom, Not functional:** the Current column holds the connection error, or `not connected`. The detail says the live checks could not run. Every other check on a MySQL Database target is then Unknown with `not checked: connection failed`.
- **Likely causes:** the server is down; no network path from the agent host to the server's port; the monitoring account is wrong or its host clause does not match the agent's address as MySQL sees it; TLS Mode `required` against a server that cannot encrypt; an anonymous account shadowing the monitoring account; Connector/J missing; for a ClusterSet target, the Router or member endpoint is wrong.
- **How to confirm:** from the agent host, as the agent's operating-system user, try the same account with the `mysql` client over the same transport. Then list anonymous accounts:

```sql
SELECT user, host FROM mysql.user ORDER BY user, host;
```

- **Fix:** open the network path on the server's port (default 3306); create the monitoring account for the right host clause (see "Connection failures" below); remove or avoid an anonymous account that shadows it; install Connector/J.
- **What it affects:** everything. No collection runs without a connection.

### Section `connection`, item `process_priv`: PROCESS privilege

- **Required value:** `PROCESS`.
- **Status rules:** `ok` and Current `granted` when the privilege probe succeeds; `fail` and Current `missing` when the server denies it; `unknown` for any other outcome.
- **What it affects:** the InnoDB and Sessions pages (InnoDB engine state and other sessions).
- **Fix:** the detail text carries the statement, written for the monitoring account as the server reports it. Run it as an administrator.

```sql
GRANT PROCESS ON *.* TO '<monitoring user>'@'<host>';
```

### Section `connection`, item `replication_client_priv`: REPLICATION CLIENT privilege

- **Required value:** `REPLICATION CLIENT`.
- **Status rules:** same as `process_priv`.
- **What it affects:** the Replication and binary log pages (binary log and replication status).
- **Fix:**

```sql
GRANT REPLICATION CLIENT ON *.* TO '<monitoring user>'@'<host>';
```

- **Version note:** the plug-in reads binary log status with `SHOW BINARY LOG STATUS` on MySQL 8.4.0 and later, and with the older `SHOW MASTER STATUS` before 8.4.0. The privilege is the same for both. You do not choose the statement; the plug-in does.

### Section `connection`, item `select_perf_schema`: Read access to performance_schema

- **Required value:** the SELECT privilege on `performance_schema`.
- **Status rules:** same as `process_priv`.
- **What it affects:** most pages read `performance_schema`.
- **Fix:**

```sql
GRANT SELECT ON performance_schema.* TO '<monitoring user>'@'<host>';
```

The documented monitoring user has a global `SELECT, PROCESS, REPLICATION CLIENT` grant on `*.*`, which covers all three privilege checks. A missing privilege here usually means the account was created with a narrower grant than the documented one:

```sql
CREATE USER 'em_monitoring'@'%' IDENTIFIED BY '<strong password>';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'em_monitoring'@'%';
```

No `SUPER` and no write privilege is needed. The account's host clause has to match the agent's address as MySQL sees it. A socket connection arrives as `localhost`.

In every grant above, `<monitoring user>` and `<host>` stand for the account shown in the Current column of the connection row. The plug-in writes the account into the statement for you, so copy the statement from the page when you can.

### Section `performance_schema`, item `enabled`: performance_schema enabled

- **Required value:** `ON at startup`.
- **Status rules:** `ok` and Current `ON` when the server reports it on; `fail` and Current `OFF` when it reports it off; `unknown` when the probe fails or returns no value (`undetermined: the server returned no value`).
- **Likely cause of OFF:** `performance_schema` is a startup option. It cannot be switched on while the server runs.
- **How to confirm:**

```sql
SHOW VARIABLES LIKE 'performance_schema';
```

- **Fix:** set `performance_schema=ON` in the server configuration file and restart the server. On a managed service such as Amazon RDS, set it in the parameter group; the change takes effect at the next reboot.
- **What it affects:** Query Analyzer, Top Waits, Memory, File I/O and the lock pages. While it is OFF, the consumer and instrument checks show `not checked: performance_schema is OFF`.

### Section `performance_schema`, item `statements_digest_consumer`: Statement digest consumers

- **Required value:** `global_instrumentation=YES, statements_digest=YES`.
- **Status rules:** `ok` when both consumers are `YES`; `fail` when either is not; `unknown` when `setup_consumers` does not list both (`undetermined: setup_consumers did not list both consumers`).
- **Current value reads like:** `global_instrumentation=YES, statements_digest=NO`.
- **How to confirm:**

```sql
SELECT NAME, ENABLED FROM performance_schema.setup_consumers
WHERE NAME IN ('global_instrumentation', 'statements_digest');
```

- **Fix:**

```sql
UPDATE performance_schema.setup_consumers SET ENABLED = 'YES' WHERE NAME IN ('global_instrumentation', 'statements_digest');
```

This change is lost at restart. To keep it, put the matching `performance_schema_consumer_*` option in the server configuration. On a managed service, put it in the parameter group.
- **What it affects:** Query Analyzer and the statement history, which read the digest summary table that the `statements_digest` consumer feeds.

### Section `performance_schema`, item `statement_instruments`: Statement instruments

- **Required value:** all `statement/%` instruments enabled and timed.
- **Status rules:** `ok` when every statement instrument is on; `fail` when none is; `warn` when some are on and some are off. Current reads `<on> of <total> on`. `unknown` when no statement instruments are listed (`undetermined: no statement instruments were listed`).
- **How to confirm:**

```sql
SELECT COUNT(*) AS total, SUM(ENABLED = 'YES' AND TIMED = 'YES') AS on_and_timed
FROM performance_schema.setup_instruments WHERE NAME LIKE 'statement/%';
```

- **Fix:**

```sql
UPDATE performance_schema.setup_instruments SET ENABLED = 'YES', TIMED = 'YES' WHERE NAME LIKE 'statement/%';
```

This change is lost at restart. To keep it, put the matching `performance_schema_instrument` option in the server configuration. On a managed service, put it in the parameter group.
- **What it affects:** Query Analyzer and the digest tables count only the statements these instruments see.

### Section `performance_schema`, item `wait_instruments`: Wait instruments

- **Required value:** file and table I/O wait instruments enabled and timed. Optional.
- **Status rules:** `ok` when, for each of file I/O and table I/O that has instruments listed, at least one is on; `warn` otherwise. Current reads `file I/O <on> of <total> on, table I/O <on> of <total> on`. `unknown` when no wait instruments are listed (`undetermined: no wait instruments were listed`).
- **Fix:**

```sql
UPDATE performance_schema.setup_instruments SET ENABLED = 'YES', TIMED = 'YES' WHERE NAME LIKE 'wait/io/file/%' OR NAME LIKE 'wait/io/table/%';
```

It is lost at restart; the persistence note under `statement_instruments` applies.
- **What it affects:** Top Waits and the File I/O pages are empty without it. Nothing else.

### Section `performance_schema`, item `memory_instruments`: Memory instruments

- **Required value:** `memory/%` instruments enabled. Optional.
- **Status rules:** `ok` when at least one memory instrument is on; `warn` when none is. Current reads `<on> of <total> on`. `unknown` when no memory instruments are listed (`undetermined: no memory instruments were listed`).
- **Fix:**

```sql
UPDATE performance_schema.setup_instruments SET ENABLED = 'YES' WHERE NAME LIKE 'memory/%';
```

It is lost at restart; the persistence note under `statement_instruments` applies.
- **What it affects:** the Memory Usage page is empty without it. Nothing else.

### Section `sys_schema`, item `installed`: sys schema installed

- **Required value:** `>= 1.5.1`.
- **Status rules:**
  - `ok`, Current `sys <version>`: the version is 1.5.1 or later.
  - `fail`, Current `sys <version> (too old)`: older than 1.5.1.
  - `fail`, Current `not installed`: the `sys` schema does not exist.
  - `fail`, Current `no SELECT on sys`: the account cannot read it.
  - `unknown`: `undetermined: no version returned`, `undetermined: unrecognised sys version '<value>'`, or any other probe failure.
- **How to confirm:**

```sql
SELECT sys_version FROM sys.version;
```

- **Fix:** install or upgrade the `sys` schema to 1.5.1 or later; it ships with MySQL 5.7 and later. If the account cannot read it:

```sql
GRANT SELECT ON sys.* TO '<monitoring user>'@'<host>';
```

- **What it affects:** the Sys pages (sessions, I/O, statements, locks, memory).

### Section `backup`, item `backup_tool`: Backup tool history

- **Required value:** a backup history table the monitoring user can read. Optional.
- **Status rules:**
  - `ok`, Current `MEB history visible` or `Percona XtraBackup history visible`: `mysql.backup_history` or `PERCONA_SCHEMA.xtrabackup_history` exists and can be read.
  - `warn`, Current `<table> is visible but not readable`: the table exists and the account cannot read it. The detail carries a `GRANT SELECT ON <table> TO <account>` statement.
  - `unknown`, Current `no backup history table found (mysql.backup_history, PERCONA_SCHEMA.xtrabackup_history)`: neither table exists. This is not a fault and not a pass.
  - `unknown` for any other probe failure.
- **Likely causes of "not found":** the server has no MySQL Enterprise Backup or Percona XtraBackup history; it is a managed service whose backups are not visible to the server; XtraBackup ran without `--history`; the estate is backed up with logical dumps or snapshots, which leave no server-side record.
- **How to confirm:**

```sql
SELECT COUNT(*) FROM mysql.backup_history;
SELECT COUNT(*) FROM PERCONA_SCHEMA.xtrabackup_history;
```

- **Fix:** none is needed when you do not use either tool. MySQL Enterprise Backup writes history by default; `--no-history-logging` turns it off. XtraBackup writes history only when the backup command includes `--history`. The documented monitoring user has a global `SELECT` grant, which already covers both tables.
- **What it affects:** the Backup page and backup thresholds only. On Amazon RDS, backups are not visible to the server, so Unknown here is expected.

### Section `license`, item `license_active`: Plug-in licence

- **Required value:** `Active`.
- **Status rules:**
  - `ok`, Current `Active`: the licence is Active, and it has no expiry or more than 30 days left.
  - `warn`, Current `Active, <n> days left` (or `1 day`): the licence is Active and expires in 30 days or fewer.
  - `fail`, Current is the status word: `License Required`, `Invalid Signature`, `Wrong Plug-in` or `Expired`.
  - `unknown`: `undetermined: licence status not available` (the status is missing or is not one of the five known words) or `undetermined: days remaining not understood`.
- **What each failing status means:**

| Status | Meaning | Fix |
|---|---|---|
| `License Required` | No key has been entered. | Enter the key in the target's License Key property. |
| `Invalid Signature` | The key text was altered. | Paste the key exactly as issued, as one line, with no wrapping and no trailing spaces. |
| `Wrong Plug-in` | The key was issued for a different plug-in, for example a general-availability key on a beta install. | Use the key issued for the plug-in you installed. |
| `Expired` | The expiry date has passed. | Request a new key. |

- **Fix:** set the key in the target's License Key property. The key is checked on the agent host every 15 minutes, and again when the property changes. Collections resume at their next interval; nothing needs a restart. The License metric's Status column names the reason.
- **What it affects:** every collection on that target stops while the status is anything but Active. The target stays Up, because availability keeps reporting. The signal is a critical incident on the License metric and the collection error `Collection stopped by license status: <status>`. MySQL Cluster and MySQL ClusterSet targets are not licensed and are never gated.

### Section `mysql_shell`, item `mysqlsh_installed`: MySQL Shell (mysqlsh) on the agent host

- **Required value:** `mysqlsh` on the agent user's PATH. Optional. ClusterSet targets only.
- **Status rules:** `ok`, Current is the first line of `mysqlsh --version`; `warn`, Current `not found`, when the program cannot be started; `unknown` when it started but hung for 10 seconds or exited with a non-zero code (`undetermined: mysqlsh --version timed out after 10s`, or `undetermined: mysqlsh --version exit <code>: <first line>`).
- **How to confirm:** as the agent's operating-system user on the agent host, not as `root`:

```bash
mysqlsh --version
```

- **Fix:** install MySQL Shell on the agent host and put `mysqlsh` on that user's PATH. The MySQL Shell package ships the Kerberos client plug-in; `mysqlsh --version` alone does not prove the plug-in is present.
- **What it affects:** without it the ClusterSet target falls back to a repository rollup (`fallback_reason MYSQLSH_NOT_FOUND`). The rollup cannot assess disaster-recovery promotion readiness: `health_status` reads `UNKNOWN` and `dr_promotion_ready` reads -1. This is a missing prerequisite, not a fault, and it raises no alert of its own.

### Section `mysql_shell`, item `adminapi_connection_shape`: ClusterSet AdminAPI connection shape

- **Required value:** TCP, a TLS mode other than `verify_ca` and `verify_identity`, and a readable Kerberos configuration file. Optional. ClusterSet targets only.
- **Status rules:** `ok`, Current `usable by mysqlsh`, when none of the three problems applies; `warn` when one or more does. Current lists them separated by `; `.

| Current value | Cause | Fix |
|---|---|---|
| `Unix socket connection` | A socket target cannot use the AdminAPI, which needs direct TCP sessions to every member. | Configure the target with TCP endpoints. |
| `TLS mode verify_ca` or `TLS mode verify_identity` | `mysqlsh` refuses these modes without a CA certificate, and this release does not provide the truststore support they need. The collection reports `TLS_TRUSTSTORE_REQUIRED`. | Set the target's TLS Mode to `required` (or `disabled`). |
| `Kerberos configuration file not readable: <path>` | The agent's operating-system user cannot read the file. `mysqlsh` would silently use `/etc/krb5.conf`, so the plug-in refuses to run it. | Check the path in the target's Kerberos Configuration File property and the file's permissions. |

- **What it affects:** each problem makes the plug-in fall back to the repository rollup, with the same consequences as `mysqlsh_installed`.

## Collection failures

These are failures that are not on the readiness page, or that stop the page from running.

### MySQL Connector/J not found

The driver is not inside the plug-in. Every collection of every MySQL target on an agent host, and every Run EXPLAIN job, stops with one message until the driver is in place. The target does not show a MySQL problem. When it is missing, the Monitoring Readiness page returns no results.

- **Message:** `MySQL Connector/J not found: no mysql-connector-j-*.jar in <directory>; files present: ...`
- **Cause and fix:** the directory is `<agentStateDir>/ip_plugin/xmyb/lib`. `<agentStateDir>` is the agent's instance directory, which `emctl status agent` prints as **Agent Home**. Put exactly one `mysql-connector-j-*.jar` there, readable by the agent's operating-system user. Connector/J 8.4.0 is the tested version. The next collection uses it; nothing needs a restart.
- **Message:** `MySQL Connector/J: N mysql-connector-j-*.jar files in <directory> (...); keep exactly one.` Two or more jars are present, usually after an upgrade. Remove all but one.
- **Message:** `MySQL Connector/J: <jar> is not usable by this plug-in - it lacks <class> ...` The file is not a Connector/J release the plug-in can link against: a renamed legacy `mysql-connector-java` build, a corrupt download, or a release outside the tested range. Replace it with `mysql-connector-j-8.4.0.jar`.
- **Message:** `MySQL Connector/J: cannot locate <agentStateDir>/ip_plugin/xmyb/lib - agentStateDir did not resolve on this agent` The agent did not hand the plug-in its instance directory. Check that `emctl status agent` shows an Agent Home, and that the plug-in was deployed to the agent after the agent was last upgraded.
- **Collections stop after a newer driver:** later 8.4.x and 9.x releases are expected to work but are not certified. Go back to 8.4.0 and report the version that failed.
- **Windows agents** are not supported. The agent must be Linux. The MySQL server can be anywhere the agent can reach.

### Connection failures

- **The target stays Down, or `Access denied` for an account you just created.** The agent connects over TCP, so the account's host clause must match the agent's address as MySQL sees it, not `localhost`. An account created as `'em_monitoring'@'localhost'` does not authenticate a remote agent.
- **`Access denied` although the account exists with the right host clause.** MySQL matches the most specific host entry first. An anonymous account (`''@'localhost'`) is more specific than `'em_monitoring'@'%'` for a connection that arrives as localhost, so the anonymous entry wins and fails. List anonymous accounts, then drop the ones you do not need:

```sql
SELECT user, host FROM mysql.user WHERE user = '';
```

- **Socket targets.** A local agent can connect over the Unix socket. The account must exist as `'<user>'@'localhost'`, the Unix Socket Path must be `mysqld`'s own socket, and Host must be empty. A target with both a host and a socket path connects over TCP.
- **TLS.** An empty TLS Mode means plaintext, the same as `disabled`. With `required`, the connection fails if the server cannot encrypt it, and the target goes Down. A value the plug-in does not recognise is treated as `required`.
- **Kerberos on the JDBC path fails while the `mysql` client works.** The collections use the Java runtime's Kerberos libraries, not the system ones, so they read the credential cache and `krb5.conf` that the agent's Java sees. Set the target's Kerberos Configuration File to a file the agent user can read, keep the ticket refreshed for the agent's operating-system user, and check that the agent's Java trusts the realm's encryption types.

### ClusterSet health

The ClusterSet Health metric reports `health_status` and `fallback_reason`. When MySQL Shell cannot be used, `health_status` reads `UNKNOWN` and `dr_promotion_ready` reads -1: promotion readiness was not assessed. The DR Promotion Ready alert fires only on 0.

| `fallback_reason` or status | Meaning | Fix |
|---|---|---|
| `MYSQLSH_NOT_FOUND` | `mysqlsh` is not on the agent user's PATH. A missing prerequisite, not a sick cluster. | See check `mysqlsh_installed`. |
| `TLS_TRUSTSTORE_REQUIRED` | The target's TLS Mode is `verify_ca` or `verify_identity`. | Use `required` or `disabled`. |
| `MEMBER_UNREACHABLE` | `mysqlsh` connected through one listed endpoint, then could not reach a different member. The AdminAPI opens its own session to every member that Group Replication considers online. | Open a network path from the agent host, on the MySQL port, to every member of every cluster. The agent host must also resolve each member's host name. |
| `KERBEROS_TICKET` | The Kerberos exchange failed before any member saw a credential. `mysqlsh` reports every such failure as `Unknown MySQL error`. | As the agent's operating-system user, run `klist`. If there is no ticket or it is expired, restore the unattended refresh (`k5start`, or a scheduled `kinit -kt <keytab> <principal>`). Other causes: an unreachable KDC, clock skew, a member without a `mysql/<host>` service principal. |
| `KERBEROS_CLIENT_UNAVAILABLE` | `mysqlsh` could not load `authentication_kerberos_client`. | Install the MySQL Shell package that ships its client plug-ins and the Kerberos client libraries. |
| `KERBEROS_CONFIG_UNREADABLE` | The target's Kerberos Configuration File is not readable by the agent's operating-system user. | See check `adminapi_connection_shape`. |
| `KERBEROS_NOT_SUPPORTED` | The endpoint refused the Kerberos client plug-in. A MySQL Router port does this: Kerberos does not pass through Router. | Configure the target with member endpoints instead of a Router port, or use password authentication. |
| `dr_promotion_ready` = 0, `health_status` `NOT_READY` | `mysqlsh` assessed the ClusterSet and a readiness check failed. A ClusterSet with no replica clusters also reads 0. | The ClusterSet DR Health page shows which check failed. |

### Run EXPLAIN job failures

- **`Unable to get credentials for defaultHostCred`.** The job needs two credentials: the target's monitoring credential, and a Host Preferred Credential on the target, a named host credential that runs as the agent's operating-system user. Set it under Setup, Security, Preferred Credentials, for the MySQL Database target type.
- **`MySQL Connector/J not found ...` or `cannot locate <agentStateDir>/ip_plugin/xmyb/lib - EMSTATE is not set in the job step`.** The first means the driver is missing or unreadable by the credential's user. The second means the credential switched user without keeping the agent's environment, usually a `sudo` rule with `env_reset` and no `env_keep`.
- **`the job step's javaHome=... does not name a JVM`.** The Java runtime that Enterprise Manager resolved for the job is not there. Check the agent installation with `emctl status agent`.
- **A syntax error on a statement copied from Query Analyzer.** Query Analyzer shows normalised digests with `?` in place of literals. Replace the placeholders with real values first.

### Metrics that look wrong

- **Query Analytics look stale on an idle server.** Keyed metrics keep their last rows when a window sees no new activity. The `active_digest_count` column is the freshness signal.
- **Backup failures are not detected.** MySQL Enterprise Backup records failed runs. Percona XtraBackup does not, so for an XtraBackup-only estate the backup-age threshold is the failure signal.
- **One metric group errors on an uncertified MySQL version.** The plug-in does not block versions it has not seen. The affected group degrades to a collection error on that group alone. Report the group and the version.
- **Collections stop reaching the repository.** The 24 Hours window stops advancing, Week and Month stay empty, and `emctl status oms -details` says "PBS may not be up" while the console works. The agent that hosts the MySQL targets usually shares a host with the Management Service or the repository database, or carries more targets than its cores allow. Plan two MySQL Database targets per vCPU on dedicated agent hosts. See the sizing section of the user guide.

## Versions and platforms

- The fix statements the page shows are the same text on every MySQL version. The one version difference this file documents, which the plug-in handles itself, is the binary log status statement: `SHOW BINARY LOG STATUS` on MySQL 8.4.0 and later, `SHOW MASTER STATUS` before.
- Certified MySQL versions are 8.4 LTS and 9.7 LTS. MySQL 8.0 is supported at a basic tier. Other versions are expected to work; the plug-in does not block a version it has not seen.
- **Managed services such as Amazon RDS.** `UPDATE` statements against `performance_schema` are lost at a restart. To keep them, put the matching option in the service's parameter group. To turn `performance_schema` on, set `performance_schema=ON` in the parameter group and reboot the instance. Managed services have no host process for an agent to see, so add them as targets manually, using the service endpoint as the host. Backups are not visible to the server there, so `backup_tool` reads Unknown.

## Where to look

The plug-in's own log is on the agent host that monitors the target. The plug-in writes its warnings and errors there. The file is `mysql_oem.log`, in the `logging` folder of the plug-in's directory under the agent's `plugins` directory:

```
plugins/ip.em.xmyb.agent.plugin_<version>/logging/mysql_oem.log
```

`<version>` is the deployed plug-in version. `emctl status agent` on the agent host prints Agent Home. If you cannot find the `plugins` directory from there, search for the file by name:

```bash
find <agent base directory> -name mysql_oem.log
```

The log rolls over at 15 MB into files named `mysql_oem-<date>-<n>.log` in the same folder, and the plug-in keeps up to 10 of them. One log serves every MySQL target that the agent monitors, and a line does not always name its target, so match lines to a target by time.

Other places that the user guide names:

- The collection-error text on the target's metric groups.
- The `License` metric's Status column, for the licence state.
- The deploy log and the agent log, for install and deploy problems. `emcli get_plugin_deployment_status -plugin=<plug-in id>` shows deployment progress.
- The WebLogic server log and the repository's wait profile, for the repository-overload pattern above.

## What to send support

Send these, with passwords and licence keys removed:

- The Monitoring Readiness page results: every check, with its panel, label, status, current value, required value and detail text.
- The plug-in version (`emcli list_plugins_on_server`).
- The Enterprise Manager version (24ai or 13.5).
- The MySQL version and edition.
- The metric group or console page involved.
- Any deploy log, agent log or collection-error text.

Do not send passwords, licence keys, keytabs or Kerberos tickets. If a statement or log line contains one, replace it with `<removed>` first.

## More help

The human-oriented version of this guide is the published troubleshooting page: https://docs.integrationplumbers.io/mysql/troubleshooting.html

Prerequisites, including the monitoring user, TLS, Unix sockets and Connector/J: https://docs.integrationplumbers.io/mysql/prerequisites.html

The monitoring pages, including the Monitoring Readiness page: https://docs.integrationplumbers.io/mysql/monitoring-pages.html
