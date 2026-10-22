# IBM Db2 plug-in for Oracle Enterprise Manager: AI troubleshooting guide

This file is written to be loaded into an AI assistant, and to be read by a database administrator. It is self-contained: the assistant needs no other document to use it.

## How to use this file

**What the plug-in is.** The IBM Db2 plug-in for Oracle Enterprise Manager, made by Integration Plumbers, monitors Db2 for Linux, UNIX and Windows (11.5 and 12.1) from an Enterprise Manager management agent. The agent connects to Db2 over JDBC with an ordinary monitoring user (`CONNECT` and `SQLADM`) and runs every collection. Nothing is installed in the database. Its plug-in ID is `ip.em.xdb2`.

**The two target types.**

| Target type | Internal name | What it represents |
|---|---|---|
| IBM Db2 Database | `ip_db2_database` | One Db2 database: single-partition, partitioned (DPF), or pureScale (member and CF health only) |
| IBM Db2 Instance | `ip_db2_instance` | One Db2 instance (database manager) on one server |

**The Monitoring Readiness page.** Both target types have a Monitoring Readiness page in the console. On an IBM Db2 Database target, each time the page opens and each time you press **Check again**, the agent runs the checks live under the target's monitoring credentials (the `readiness_detail` metric; nothing is stored). For each check the page shows a status word, the label, what it **needs**, what is set now (**current**), a detail sentence, and, where a statement fixes it, the statement under **Statement to run** with a **Copy to Clipboard** button. The page never runs a statement itself.

**To use this file with the page.**

1. Open the target's Monitoring Readiness page and press **Check again**.
2. Read the note under the button. *Checked live on the agent at* a time means the live check answered. Any other note means the panels show stored data (see "When the page shows stored data" below).
3. Copy every item that is not OK: its panel, label, status word, current value, needs value, detail text and statement.
4. Give this file and those results to your assistant, with the Db2 version, the Enterprise Manager version (24ai or 13.5), and whether the agent runs on the Db2 server.
5. Find each item below by its section id and item id, which are in the headings. The page shows panel titles, not ids; the table under "Readiness checks" maps one to the other.

**Every statement in this file is for an administrator to review and run.** The plug-in changes nothing on the server. The monitoring user holds no authority to change configuration, so a fix statement fails if you run it as that user. Run SQL statements connected to the database as a user with the authority the statement needs; run `UPDATE DB CFG` and other command line processor (CLP) commands as the instance owner or a user with SYSADM, SYSCTRL or SYSMAINT. From a shell, prefix a CLP command with `db2`, for example `db2 "UPDATE DB CFG FOR SAMPLE USING MON_REQ_METRICS BASE"`.

**Remove secrets before you share anything.** Passwords, licence keys, keytabs and Kerberos tickets must not appear in text you send to an assistant or to support.

## Status words

| Probe status | Page word | Meaning |
|---|---|---|
| `ok` | OK | The check ran and the requirement is met. |
| `warn` | Attention | The feature works with a limit, or an optional feature is not set up. |
| `fail` | Not functional | A required check ran and failed. The pages that depend on it are empty or wrong. |
| `unknown` | Unknown | The check did not run or could not decide. Unknown means not checked. It is never a pass. |

Each item is either required or **optional** (the page shows an *optional* badge). An optional item that fails counts as Attention, never Not functional, and an optional item that is Unknown does not colour its panel. A panel shows the worst weight of its items in the order Not functional, Attention, Unknown, OK; a panel reads Unknown only when every item in it is Unknown.

The line above the panels reads one of: *All checks pass.*, *No check needs attention; N could not be judged yet.*, *1 check needs attention.*, *N checks need attention.*, or *No check could be judged yet.* The Overview page's **Readiness** row counts the same checks once an hour (the `readiness_summary` metric), so it can be up to an hour behind the page.

## When the page shows stored data instead of the live check

While the live check runs, and when it does not answer, the page fills the panels from the latest stored collections in the Enterprise Manager repository: `License`, `CollectorStatus`, `Monitor_Metrics` and `HADR_Readiness`. The caption then reads *Read from the latest stored collections when the page opened.*, sometimes with when Collector Status was collected.

| What the note says | Meaning | What to do |
|---|---|---|
| *Checking live on the agent…* | The live check is running. **Check again** is disabled until it settles. | Wait up to 30 seconds. |
| *The live check is not available on this target (it needs plug-in metadata 4.6) or did not answer, so the panels show the latest stored collections.* | The target runs plug-in metadata older than 4.6, or the read failed or returned nothing. | Deploy the current plug-in to the agent that monitors the target. Check that the target's agent is up and reachable from the OMS (`emctl status agent` on the agent host). Press **Check again**. |
| *The live check did not answer within 30 seconds, so the panels show the latest stored collections. Check again to retry.* | The agent did not answer in 30 seconds. | Check that the agent host is not overloaded, then press **Check again**. |

In stored mode some items are missing, because only the live check can answer them: the monitoring connection, the supported version and topology, the monitor authority, and the whole **Deadlock Capture** panel. A stored item that has no data yet reads Unknown with *not collected yet* and says how often its source is collected (License every 15 minutes, Collector Status every 5 minutes, Monitor_Metrics every 60 minutes, HADR_Readiness every 5 minutes). A source that could not be read says *could not be read from the Enterprise Manager repository. Reload the page to try again.*

**The IBM Db2 Instance target has no live check.** Its page always shows stored data, with two panels: **Connection and Collection** (licence and metric collection) and **Diagnostic Log Monitoring**. **Check again** re-reads the stored data.

## Readiness checks

These are the items the live check emits on an IBM Db2 Database target, in page order. The section id is the panel; the item id identifies the row.

| Panel (section id) | Item label (item id) | Required | Live or stored |
|---|---|---|---|
| Connection and Collection (`connection`) | Monitoring connection (`connection`) | yes | live only |
| Connection and Collection (`connection`) | Plug-in license (`license`) | yes | both |
| Connection and Collection (`connection`) | Supported Db2 version and topology (`platform`) | yes | live only |
| Connection and Collection (`connection`) | Monitor authority (MON_GET_* functions) (`monitor_authority`) | yes | live only |
| Connection and Collection (`connection`) | Metric collection (`collection`) | yes | both |
| Connection and Collection (`connection`) | *GroupName* collection (`group:<GroupName>`), one per failing group | yes, except four optional groups | both |
| Connection and Collection (`connection`) | Groups disabled (`disabled`), only when a group is disabled | yes | both |
| Connection and Collection (`connection`) | Groups not collected yet (`pending`), only when a group has never collected | optional | both |
| Monitor Switches (`monitor_switches`) | Request metrics (mon_req_metrics) (`mon_req_metrics`) | yes | both |
| Monitor Switches (`monitor_switches`) | Activity metrics (mon_act_metrics) (`mon_act_metrics`) | yes | both |
| Monitor Switches (`monitor_switches`) | Object metrics (mon_obj_metrics) (`mon_obj_metrics`) | yes | both |
| Deadlock Capture (`deadlock_capture`) | Deadlock event monitor (`event_monitor`) | optional | live only |
| HADR (`hadr`) | HADR configured or HADR checks (`configured`) | optional | both |
| HADR (`hadr`) | Takeover ready - *db* / *standby* (`takeover@<db>/<standby>`) | optional | both |
| HADR (`hadr`) | Standby connected - *db* / *standby* (`connected@<db>/<standby>`) | optional | both |
| Diagnostic Log Monitoring (`diag_log`) | Management Agent on the Db2 server (`local_agent`) | optional | both |

The OMS licence instance count is **not** a readiness check. When it fails it shows up as the `group:License` item (see "The OMS licence instance count" below).

In the fix statements below, `<monitoring user>` is the user the target connects as (the page prints the actual name, from Db2's `CURRENT USER`), and `<db>` is the database name (the page prints it, from `CURRENT SERVER`).

### How to read an Unknown reason

| Current value | Meaning |
|---|---|
| `not checked` with *Not checked: the connection failed.* | The monitoring connection failed, so the checks that need it did not run. Fix `connection` first. |
| `not checked` with *Not checked: an HADR standby accepts no connections.* | The database is an HADR standby without reads on standby. See `connection` below. |
| `undetermined` | The check ran and failed for a reason other than the one it tests. The detail carries Db2's message. Read it as the evidence. |
| `not determined` | A target property the check needs has not resolved yet. |
| `(not set)` | The value was empty. |

A detail that ends in *Driver reason:* carries the JDBC driver's message, as `SQLSTATE <state>: <message>` when there is an SQLSTATE.

### Section `connection`, item `connection`: Monitoring connection

- **Needs:** connects.
- **Status rules:** `ok` when the monitoring credentials connect and run a statement; `fail` when they do not; `ok` on an HADR standby that refuses connections (SQL1776N), because that is expected.
- **Symptom, OK:** current reads `connected to <db> as <user>`.
- **Symptom, Not functional:** current reads `cannot connect`, and every other live item reads `not checked`. The detail is one of:
  - *The database refused the connection: the monitoring user lacks the CONNECT privilege.* The page prints the fix:

    ```sql
    GRANT CONNECT ON DATABASE TO USER <monitoring user>
    ```
  - *Cannot monitor the database (it is not down):* followed by the cause. The causes the plug-in recognises: authentication failed (check the monitoring credentials); no monitoring password is set; the monitoring user lacks a privilege; the database is quiesced and the monitoring user has no QUIESCE_CONNECT authority; the IBM Db2 JDBC driver could not be loaded; Kerberos authentication failed; and three TLS causes (see "TLS connections and the client truststore" below).
  - *The database did not answer: it is down, or unreachable from the agent host. Check the host, port and database name on the target.* A connection reset, end of stream, timeout, refused connection or unknown host is always read as this, even on a TLS target.
- **Symptom on an HADR standby:** status OK, current `HADR standby (SQL1776N reason <n>)`. Reason 1 means reads on standby are off: the standby accepts no connections, so its groups are not collected. Monitor the primary, or set `DB2_HADR_ROS=ON` on the standby instance. Reason 4 means the standby is in its replay-only window; collection resumes when the window closes.
- **How to confirm:** from the agent host, as the agent's operating-system user, connect to the same host, port and database with the same user, using any Db2 client. The detail text already names the cause the driver reported.
- **Fix:** start the database or open the network path to its port; correct the target's Host, Port or Database Name properties; set or correct the target's monitoring credentials (below); grant CONNECT.

  ```
  emcli set_monitoring_credential \
    -target_name="<target_display_name>" \
    -target_type="ip_db2_database" \
    -set_name="DB2DatabaseMonitoringCreds" \
    -cred_type="DB2DatabaseCreds" \
    -attributes="DB2Username:<user>;DB2Password:PWTAG" \
    -input_file="PWTAG:<file holding only the password>"
  ```
- **RESTRICTIVE databases, including every Amazon RDS for Db2 database.** Without grants on the driver's `NULLID` packages every query fails with `SQLCODE=-551, SQLSTATE=42501`, naming a `NULLID` package. Check with `SELECT VALUE FROM SYSIBMADM.DBCFG WHERE NAME = 'restrict_access'`. On RDS:

  ```sql
  GRANT ROLE ROLE_NULLID_PACKAGES TO USER <monitoring user>;
  GRANT EXECUTE ON PACKAGE NULLID.ATSQ0A TO USER <monitoring user>;
  ```

  On a self-managed RESTRICTIVE database, generate the grants and run the output:

  ```sql
  SELECT 'GRANT EXECUTE ON PACKAGE NULLID."' || PKGNAME || '" TO USER <monitoring user>;'
    FROM SYSCAT.PACKAGES WHERE PKGSCHEMA = 'NULLID';
  ```
- **What it affects:** everything. No collection runs without a connection.

### Section `connection`, item `license`: Plug-in license

- **Needs:** Active.
- **Status rules:** `ok` for `Active`; `warn` for `Grace Period`; `fail` for any other status; `unknown` when the status could not be computed. In stored mode `Exceeded Limit` reads `warn`.
- **Symptom, Attention (`Grace Period`):** *The key has expired. Collection continues for 14 days after the expiration date, then stops: set a renewed key in the target's Plug-in Licence Key credential (Monitoring Configuration).*
- **Symptom, Not functional:** current is the status word (`License Required`, `Invalid Signature` or `Expired`), and the detail says *Every other metric collection is paused until the license is resolved.* The target stays Up, every page is nearly empty, and the other groups report *Collection stopped by license status*.
- **Likely causes:** no key set; a key typed wrongly; a beta (`ip.em.xdbb`) key on the GA plug-in, which reads `Invalid Signature`; an expired key.
- **Fix:** set a valid key in the target's licence credential set, through a file so the key is never on a command line:

  ```
  emcli set_monitoring_credential -target_name="<target_display_name>" -target_type="ip_db2_database" \
    -set_name="DB2LicenseMonitoringCreds" -cred_type="DB2LicenseCreds" \
    -attributes="DB2LicenseKey:LICTAG" -input_file="LICTAG:<file holding only the licence key>"
  ```

  For an IBM Db2 Instance target use `-target_type="ip_db2_instance" -set_name="DB2InstanceLicenseMonitoringCreds" -cred_type="DB2InstanceLicenseCreds"`. The new key takes effect at the next collection, with no restart. A target upgraded from before metadata 4.8 may still carry the key in the old *Plugin Licence Key* property, which is read while the credential is empty. For a trial or a renewal, email sales@integrationplumbers.io.
- **What it affects:** every metric group except License, availability, version detection, CollectorStatus and the readiness summary.

### Section `connection`, item `platform`: Supported Db2 version and topology

- **Needs:** Db2 11.5 or 12.1; single partition or DPF (pureScale: health only).
- **Current reads like:** `Db2 12.1, SINGLE`.
- **Status rules:** `ok` for a supported version on a single-partition or DPF database; `warn` on pureScale; `fail` for an unsupported version or an unknown topology; `unknown` when the version properties have not resolved.
- **Symptoms and fixes:**
  - Unsupported version: *Unsupported Db2 version &lt;v&gt;: this plug-in collects Db2 11.5 and 12.1 only, so this group is gated off.* Availability and CollectorStatus still collect.
  - After an in-place Db2 upgrade, or when the version reads *not determined*, refresh the target's properties on the agent host:

    ```
    emctl reload agent dynamicproperties <target name>:ip_db2_database
    ```
  - pureScale (Attention): only member and CF health is collected (`Member_Status`, `PureScale_Members`, `PureScale_CFs`, `PureScale_GBP`); implemented, not lab-certified. Every other group stays off. There is nothing to fix.
  - DPF (OK): every metric group is collected over all members, except `HADR_Status`, `HADR_Readiness` and `Diag_Log_File_Monitoring`, which are not certified on DPF.

### Section `connection`, item `monitor_authority`: Monitor authority (MON_GET_* functions)

- **Needs:** SQLADM, or EXECUTE on the MON_GET_* functions.
- **Status rules:** `ok` and current `granted` when the monitoring user may run `MON_GET_DATABASE`; `fail` and current `not granted` on SQL0551N (SQLSTATE 42501); `unknown` and `undetermined` for any other error; `unknown` and `not checked` when the connection failed.
- **Symptom, Not functional:** *The monitoring user may not run MON_GET_DATABASE, so every metric group fails with SQL0551N.* Most metric groups report a collection error naming `SQL0551N`.
- **Fix:** the page prints:

  ```sql
  GRANT SQLADM ON DATABASE TO USER <monitoring user>
  ```

  SQLADM carries EXECUTE on the `MON_GET_*` table functions without data access. Never grant SYSADM, DBADM or DATAACCESS for monitoring. Where SQLADM is not allowed, grant EXECUTE on each `MON_GET_*` function the collections use instead; this check tests only `MON_GET_DATABASE`, so with granular grants it can pass while a group still fails with SQL0551N.
- **What it affects:** nearly every metric group.

### Section `connection`, item `collection`: Metric collection

- **Needs:** no collection errors.
- **Current reads like:** `78 groups, none failing` or `2 of 78 groups failing`.
- **Status rules:** `fail` when any failing group is required; `warn` when only optional groups fail; `ok` when none fail; `unknown` when no group is registered with the collector.
- **What to do:** each failing group is listed under it as its own item, `group:<GroupName>`. Fix those.
- **Detail when none fail:** *Groups that are not configured on this database are expected to be empty.* An empty page with no failing group is usually a feature that is not set up (deadlock capture, HADR) or a group not collected yet.

### Section `connection`, item `group:<GroupName>`: GroupName collection

- **Needs:** collects without error.
- **Current reads like:** `COLLECTION_ERROR`, or `COLLECTION_ERROR (12 in a row)`.
- **Status rules:** `fail` for a required group; `warn` for the four optional groups `HADR_Readiness`, `HADR_Status`, `Diag_Log_File_Monitoring` and `Deadlocks`.
- **Detail:** the error the group's last collection returned, usually Db2's message (`SQLSTATE <state>: <message>`).
- **How to read it:**
  - `SQL0551N`, SQLSTATE `42501` or `SQLCODE=-551`: the monitoring user lacks an authority. When the group is required, the page prints `GRANT SQLADM ON DATABASE TO USER <monitoring user>`. `SQL0552N` also means a missing authority but prints no statement; grant the authority the message names.
  - `group:License`: the License group failed. The usual cause is the OMS licence instance count; see that section below. The live `license` item can still read Active.
  - `Kerberos authentication failed`: see `connection`.
- **Where to look next:** the group's row in the `CollectorStatus` metric (`Status`, `Reason`, `ConsecutiveErrors`, `LastAttemptEpoch`, `LastDurationMs`), and the plug-in log (see "Where to look").

### Section `connection`, item `disabled`: Groups disabled

- **Needs:** collecting.
- **Current reads like:** `3 of 70 groups disabled`.
- **Status rules:** `fail` when every data group is disabled; `warn` otherwise. Shown only when a group is disabled.
- **Detail:** each reason, followed by the groups it disables. The reasons:
  - *Collection stopped by license status: &lt;status&gt;*: fix `license`.
  - *Unsupported Db2 version* or *Unknown topology*: fix `platform`.
  - *Not collected on a partitioned (DPF) database* (HADR and diagnostic-log groups): expected on DPF.
  - *Not collected on a pureScale cluster yet*: expected on pureScale.
  - an HADR standby without reads on standby: expected; monitor the primary or turn on reads on standby.
  - the agent-load throttle (the collector skipped the collection while the agent host was busy): raise the throttle's thresholds in `<agentStateDir>/ip_plugin/xdb2/collection-throttle.conf`, or remove the file to turn the throttle off.
- **Fix:** none is printed. Fix the cause the reason names.

### Section `connection`, item `pending`: Groups not collected yet

- **Needs:** collected once. Optional, so it never colours the panel.
- **Current reads like:** `9 groups`.
- **Detail:** *Each appears after its first scheduled collection:* followed by the groups.
- **What to do:** wait for the groups' collection intervals. Groups that compute a change between two collections (for example `Wait_Time`, `Index_Activity`, `Application_Statistics`) write their first row one interval after their first collection. Daily groups (`Unused_Indexes`, the configuration snapshot) can take a day.

### Section `monitor_switches`, items `mon_req_metrics`, `mon_act_metrics`, `mon_obj_metrics`

- **Needs:** BASE or EXTENDED, for each of the three database configuration parameters.
- **What each feeds:** `mon_req_metrics`, CPU, rows and wait time per request (Performance, Waits); `mon_act_metrics`, per-statement work (the SQL page); `mon_obj_metrics`, buffer pool and table space I/O (Performance, Storage).
- **Status rules:** `ok` for BASE or EXTENDED; `fail` for NONE; `unknown` for any other value, or when the configuration could not be read.
- **Symptom, Not functional:** current `NONE`, and *At NONE the MON_GET_\* values read 0, and the pages look idle while measuring nothing.* The pages show healthy-looking zeros. The `Monitor_Metrics` group also raises a Warning.
- **Likely cause:** a database created before Db2 9.7 and upgraded since keeps NONE; newer databases default to BASE.
- **Fix:** the page prints one statement per switch at NONE, to run from the Db2 command line processor as a user with SYSADM, SYSCTRL or SYSMAINT. It takes effect without a restart:

  ```
  UPDATE DB CFG FOR <db> USING MON_REQ_METRICS BASE
  UPDATE DB CFG FOR <db> USING MON_ACT_METRICS BASE
  UPDATE DB CFG FOR <db> USING MON_OBJ_METRICS BASE
  ```
- **How to confirm:** on the Db2 server, `db2 get db cfg for <database> | grep -i MON_REQ_METRICS` must show `BASE` or `EXTENDED`; check `MON_ACT_METRICS` and `MON_OBJ_METRICS` the same way.

### Section `deadlock_capture`, item `event_monitor`: Deadlock event monitor

- **Needs:** an active locking event monitor. Optional.
- **What it affects:** **Recent Deadlocks** on the Locks page, and the Deadlocks tile there. Deadlock counts and the `deadlocks_rate` alert work without it.
- **Status rules:** `ok` when a usable locking event monitor writes to tables, is active, and `MON_DEADLOCK` lets it record; `warn` for every other outcome; `unknown` when the connection failed or the event monitor catalog could not be read.
- **Symptom `none`:** no locking event monitor is set up. Db2 records deadlock participants only through one, and the plug-in never creates it. A DBA runs the statements the page prints, once, connected to the database:

  ```sql
  CREATE EVENT MONITOR IP_DEADLOCKS FOR LOCKING WRITE TO TABLE LOCK (TABLE LOCK_IP_DEADLOCKS), LOCK_PARTICIPANTS (TABLE LOCK_PARTICIPANTS_IP_DEADLOCKS), LOCK_PARTICIPANT_ACTIVITIES (TABLE LOCK_PARTICIPANT_ACTIVITIES_IP_DEADLOCKS), LOCK_ACTIVITY_VALUES (TABLE LOCK_ACTIVITY_VALUES_IP_DEADLOCKS), CONTROL (TABLE CONTROL_IP_DEADLOCKS) AUTOSTART;
  SET EVENT MONITOR IP_DEADLOCKS STATE 1;
  GRANT SELECT ON LOCK_IP_DEADLOCKS TO USER <monitoring user>;
  GRANT SELECT ON LOCK_PARTICIPANTS_IP_DEADLOCKS TO USER <monitoring user>;
  GRANT SELECT ON LOCK_PARTICIPANT_ACTIVITIES_IP_DEADLOCKS TO USER <monitoring user>
  ```

  Creating the event monitor needs SQLADM or DBADM.
- **Symptom `<evmon>, MON_DEADLOCK NONE`:** the monitor is active but Db2 sends it no deadlock. Fix:

  ```
  UPDATE DB CFG FOR <db> USING MON_DEADLOCK WITHOUT_HIST
  ```
- **Symptom `<evmon>, inactive`:** the monitor exists but is not active. Fix:

  ```sql
  SET EVENT MONITOR <evmon> STATE 1
  ```
- **Symptom `not usable`:** the monitor writes no LOCK, LOCK_PARTICIPANTS or LOCK_PARTICIPANT_ACTIVITIES table, or a table lacks a column the plug-in reads (LOCK: `EVENT_ID`, `EVENT_TYPE`, `EVENT_TIMESTAMP`; LOCK_PARTICIPANTS: `PARTICIPANT_NO`, `APPLICATION_HANDLE`, `APPL_NAME`, `AUTH_ID`; LOCK_PARTICIPANT_ACTIVITIES: `PARTICIPANT_NO`, `ACTIVITY_TYPE`, `STMT_TEXT`). No statement is printed. Create a monitor with the statements above.
- **Symptom `<evmon>, not readable`:** the monitor is set up, but the Deadlocks group's last collection could not read its tables, usually because the monitoring user lacks SELECT on them. Grant SELECT on its LOCK, LOCK_PARTICIPANTS and LOCK_PARTICIPANT_ACTIVITIES tables, in the schema they were created in.
- **Which monitor is used:** `IP_DEADLOCKS` if it exists, otherwise the first locking event monitor by name that writes to tables.
- **To remove capture:** `SET EVENT MONITOR IP_DEADLOCKS STATE 0`, then `DROP EVENT MONITOR IP_DEADLOCKS`, then drop its tables.

### Section `hadr`, item `configured`: HADR configured, or HADR checks

- **Optional.** No statement is ever printed in this panel.
- **Status rules and symptoms:**
  - OK, current `not configured`: *HADR is not configured on this database, so the HADR page stays empty. Nothing to fix unless you use HADR.* (`hadr_local_host` is blank.)
  - OK, current `standby`: the database is an HADR standby that accepts no connections. Open the primary's target for takeover readiness.
  - Unknown, current `no standby`: *HADR is configured (hadr_local_host is set), but MON_GET_HADR returned no standby: HADR may not be started on this database.* Check with `db2pd -db <db> -hadr` on the server, and start HADR if it should run.
  - Unknown, current `undetermined`: *MON_GET_HADR could not be read:* followed by Db2's message.
- **What it affects:** the High Availability page and the HADR alerts.

### Section `hadr`, items `takeover@<db>/<standby>` and `connected@<db>/<standby>`

One pair per standby the primary reports, for example `takeover@SAMPLE/1`.

- **Takeover ready - db / standby.** Needs `ready`. `ok` for ready, and for an auxiliary standby (which cannot reach peer state by design); `fail` for `not ready`; `unknown` otherwise. Optional, so it reads Attention at worst. The detail is the readiness assessment: *Standby is in peer state, connected, and ready for takeover*, or the problems found, joined by semicolons: *connection congested*, *not connected (&lt;status&gt;)*, *standby still catching up (remote catchup)*, *state &lt;s&gt; (peer state not reached)*, *replay-only window active*, *&lt;n&gt; missed heartbeat(s)*.
- **Standby connected - db / standby.** Needs `CONNECTED`. `ok` when connected; `fail` with the connection status otherwise; `unknown` when empty. The High Availability page shows the log gap and replay lag.
- **Likely causes:** the standby is down or HADR is stopped on it; a network problem between primary and standby (heartbeats missed, congestion); the standby is still catching up after a restart.
- **How to confirm:** `db2pd -db <db> -hadr` on the primary and on the standby.

### Section `diag_log`, item `local_agent`: Management Agent on the Db2 server

- **Needs:** local agent (local = 1). Optional.
- **What it affects:** **Diagnostic Log Matches** on the Locks page, the instance target's Diagnostics page, and the `Diag_Log_File_Monitoring` alerts. The plug-in reads `<DIAGPATH>/db2diag.log` from the file system, so the agent must run on the Db2 server.
- **Status rules:** `ok` and current `local` when the target's `local` property is 1 (*db2diag.log is scanned on every collection.*); `warn` and current `remote` otherwise; `warn` and current `disabled` when the version gate disables it; `unknown` and `not determined` when the property did not resolve.
- **Symptom `remote`:** *The Management Agent is not on the Db2 server (local = 0), so db2diag.log is not read. To turn it on, monitor the database with a Management Agent installed on the Db2 server.*
- **How `local` is decided:** the agent compares the target's Host property with its own host name and addresses (IPv4 and IPv6, `localhost` and `::1` included). A Host given as a virtual IP or a DNS alias the agent host does not resolve to reads remote.
- **Fix:** none is printed. Monitor the database from an agent installed on the Db2 server, with the Host property set to a name or address that resolves to that server. Not possible on Amazon RDS for Db2, Db2 on OpenShift or Kubernetes (Db2U), or IBM Db2 SaaS, where the agent is always remote.
- **On a partitioned (DPF) database** diagnostic-log monitoring is not collected, whatever this item reads.

## Collection failures and Enterprise Manager set-up

### The OMS licence instance count

A licence key that names an instance count (not `Unlimited`) is checked against the number of IBM Db2 Database targets, which the plug-in counts by asking the OMS. IBM Db2 Instance targets never count and never contact the OMS.

- **Symptom:** on Monitoring Readiness, the item **License collection** (`group:License`) reads Not functional with current `COLLECTION_ERROR`, while the live **Plug-in license** item can read Active. The other metric groups keep collecting.
- **Messages and causes:**
  - *A limited-instance licence counts the plug-in's targets through the OMS, and this target does not have &lt;settings&gt; set.* The settings are named: **OMS Host (ip_db2_database_oms_host)**, **OMS Port (ip_db2_database_oms_port)** (or *a numeric OMS Port*), and **IBM DB2 OMS Monitoring Credentials (credential set DB2OmsMonitoringCreds)**.
  - *Unable to reach the OMS over HTTPS for the licence instance count, and the cleartext HTTP fallback is disabled.* The usual cause is an OMS certificate the agent's Java does not trust.
  - *OMS rejected the licence-count credentials with HTTP 401* (or 403): the OMS user or password in the credential set is wrong, or the user cannot view the targets.
  - *The OMS gave no well-formed target list*: the OMS answered with something other than a target list.
- **Fix, settings:** set the OMS Host to the OMS host name and the OMS Port to the OMS console HTTPS port, as target instance properties, on every target with a limited key. Set the credential, an Enterprise Manager user that can view the `ip_db2_database` targets:

  ```
  emcli set_monitoring_credential -target_name="<target_display_name>" -target_type="ip_db2_database" \
    -set_name="DB2OmsMonitoringCreds" -cred_type="DB2OmsCreds" \
    -attributes="DB2OmsUsername:<em user>;DB2OmsPassword:PWTAG" \
    -input_file="PWTAG:<file holding only the password>"
  ```
- **Fix, certificate:** import the OMS certificate chain into the truststore of the Java the collector runs on: the `JAVA_HOME` in the agent's `<agent instance>/sysman/config/emd.properties` (for the central agent on the OMS host, the OMS home's JDK). As the agent owner:

  ```
  J=<the JAVA_HOME from emd.properties>
  $J/bin/keytool -printcert -sslserver <oms host>:<oms console port> -rfc > oms_chain.pem
  csplit -s -z -f oms_cert- oms_chain.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
  for f in oms_cert-*; do
    $J/bin/keytool -importcert -noprompt -trustcacerts -alias "em-oms-$f" -file "$f" \
      -keystore $J/jre/lib/security/cacerts -storepass <truststore password, default changeit>
  done
  ```

  On JDK 9 or later the file is `$J/lib/security/cacerts`. An agent patch that replaces the JDK replaces the truststore, so re-check after patching. Where the certificate cannot be imported, the target's **OMS API Communication** property (`ip_db2_database_license_verification_mode`) can be `SECURE` (HTTPS without a certificate check). `INSECURE` also allows a cleartext HTTP fallback that sends the OMS password Base64-encoded; use it in a lab only. The default, `STRICT`, verifies the certificate and host name.
- **Short outages:** a count under 7 days old stands in while the OMS cannot be reached, and the plug-in logs that it used it.
- **Over the limit:** when the count works and more targets are monitored than the key licenses, the status is `Exceeded Limit`: collection continues, and Monitoring Readiness reads Attention.

### TLS connections and the client truststore

The target's **Use SSL/TLS?** property (`ip_db2_database_use_secure`) turns on TLS. The truststore is the credential set *IBM DB2 Client Truststore Monitoring Credentials* (`DB2TruststoreMonitoringCreds`): Client Truststore Location (an absolute path on the agent host), Client Truststore Type and Client Truststore Password. With no truststore set, the agent Java's default `cacerts` is used. A TLS problem is never reported as the database being down.

The monitoring connection item's detail names the TLS cause:

| Detail | Fix |
|---|---|
| *the server's TLS certificate is not trusted. Add its certificate, or the CA that signed it, to the truststore set on the target.* | Import the server certificate or its CA into the truststore file, or point the truststore credential set at a file that holds it. |
| *the server's TLS certificate does not name the host this target connects to (TLS hostname validation).* | Connect by a host name the certificate holds, or set **TLS Hostname Validation** (`ip_db2_database_ssl_hostname_validation`) to `OFF` to keep the trust check without the name check. |
| *the TLS handshake failed: no TLS protocol version or cipher in common with the server.* | Compare the server's `SSL_VERSIONS` and `SSL_CIPHERSPECS` with what the agent's Java supports. |

For Amazon RDS for Db2 over TLS, import every certificate in AWS's CA bundle, not only the first.

**Jobs on a TLS target.** RUNSTATS, Force Application, Online Backup (including **Back Up Database**) and Explain SQL Statement use the same truststore credential set. On a target with **Use SSL/TLS?** = `yes` they need the set even when the target relies on the Java default `cacerts`. Without it Enterprise Manager fails the job at once with *Unable to resolve credential reference* or *Default preferred credentials are not set*. Point the set at `<agent JDK>/jre/lib/security/cacerts` (`<agent JDK>/lib/security/cacerts` on JDK 9 or later), with the type that `keytool -list -keystore <that file>` reports. The file must be readable by the agent owner. The jobs recognise `yes`, `YES` and `Yes`.

### Kill: preferred host credentials and a local agent

**Kill** on the Sessions page and on a root blocker's row on the Locks page submit the job *Kill IBM Db2 Application* (`ip_db2_kill_application`), which runs `db2 force application` on the Db2 server. It runs without asking for credentials, so the target needs preferred credentials.

- **Message:** *The kill job could not run. Check that preferred host credentials are set for this target.*
- **Fix:** set the target's preferred *IBM DB2 Database Host Credentials* (`DB2HostCreds`) to the Db2 instance owner's operating-system account on the Db2 server, in the console (**Setup → Security → Preferred Credentials →** *IBM Db2 Database* **→** *IBM DB2 Database Host Credentials* **→** the target) or with EM CLI:

  ```bash
  emcli set_preferred_credential -set_name=DB2HostCreds -target_type=ip_db2_database -target_name=<target> -credential_name=<named credential>
  ```
- **Message:** *ERROR: refusing to run: this job acts on the Db2 instance on the agent's own host…*. The agent is not on the Db2 server (`local` is not 1). The local jobs (start, stop, quiesce, unquiesce, archive log and kill) need it. On a remote agent, the remote admin job *IBM Db2 - Force Application (remote)* forces an application over the database connection instead, as the admin credentials user.
- **Message on Linux:** *Can't open perl script ".../killagent.pl": Permission denied*. The instance owner cannot read the plug-in's files. Add it to the agent installation's group, for example:

  ```bash
  usermod -aG <agent install group> db2inst1
  ```
- **Other outcomes:** *Application handle &lt;n&gt; was forced off the database.* is success. `SQL1230W` means the application had already gone. Every kill stays in **Enterprise → Job → Activity**.

### Back Up Database and the remote admin jobs: admin and agent-owner credentials

**Back Up Database** on the Backup page submits *IBM Db2 - Online Backup (remote)* (`ip_db2_admin_backup`, job type 1.6). It runs `BACKUP DATABASE … ONLINE` through `SYSPROC.ADMIN_CMD` on the database connection, so it works from a local or a remote agent. It does not use the host credentials of the Kill job.

- **Needs:** Full privilege on the target for the user who submits it; the target's preferred *IBM DB2 Database Admin Credentials* (`DB2AdminCreds`), a Db2 user with SYSADM, SYSCTRL or SYSMAINT; the target's preferred *IBM DB2 Plug-in Agent Owner Credentials* (`DB2AgentOwnerCreds`), the operating-system account that owns the agent installation; and on a TLS target, the truststore credential set.
- **Message:** *The backup of &lt;db&gt; did not run: a preferred credential it needs is not set for this target (IBM DB2 Database Admin Credentials, or IBM DB2 Plug-in Agent Owner Credentials), or the agent is unreachable.* Set the credentials:

  ```bash
  emcli set_preferred_credential -set_name=DB2AdminCreds \
        -target_name=<target> -target_type=ip_db2_database \
        -credential_name=<named credential>
  emcli set_preferred_credential -set_name=DB2AgentOwnerCreds -target_type=ip_db2_database -target_name=<target> -credential_name=<agent owner credential>
  ```

  Without the agent owner credential Enterprise Manager fails a plug-in job with *Unable to get credentials for defaultHostCred*.
- **Message:** *Enterprise Manager did not run the backup job: … Check that you have Full privilege on this target and that its agent is up, then try again.*
- **Db2's refusals, which the job puts in plain words first:**

  | Code | Meaning |
  |---|---|
  | `SQL2413N` | Online backup needs archive logging. The database uses circular logging (`LOGARCHMETH1` is `OFF`). Turn on archive logging; Db2 then requires one offline backup, taken on the server. |
  | `SQL1116N` | The database is in backup pending. An offline backup on the server clears it. |
  | `SQL2036N` | The backup directory does not exist on the database server, or the instance owner cannot write it. |
  | `SQL2061N` | Access to the directory was denied. |
  | `SQL2419N` | The disk filled. |
  | `SQL1092N` | The admin user lacks SYSADM, SYSCTRL or SYSMAINT. On Amazon RDS for Db2 this is expected: the master user does not hold them. |
  | `SQL0551N` | The admin user lacks a privilege, most often EXECUTE on `SYSPROC.ADMIN_CMD`. |

  For an admin user without SYSADM, SYSCTRL or SYSMAINT, `GRANT EXECUTE ON PROCEDURE SYSPROC.ADMIN_CMD TO USER <admin user>;` covers the procedure; the backup itself still needs SYSMAINT or higher, which can be given through an operating-system group with `db2 update dbm cfg using SYSMAINT_GROUP <group>`.
- **Partitioned (DPF) databases are refused:** without `ON ALL DBPARTITIONNUMS` the job would back up only the partition its connection runs on, which cannot restore the database. The dialog refuses a DPF target, and the job itself counts the database partitions before `BACKUP` and, for more than one, fails naming DPF and `ON ALL DBPARTITIONNUMS`, running nothing, however it was submitted. Back up every partition on the server with `db2 backup database <db> on all dbpartitionnums ...`. If the count cannot be read, the job also refuses: the admin user needs EXECUTE on `SYSPROC.DB_MEMBERS` (PUBLIC holds it unless the database was created `RESTRICTIVE`; otherwise `GRANT EXECUTE ON FUNCTION SYSPROC.DB_MEMBERS TO USER <admin user>;` or SQLADM).
- **Deploy to the agents too:** an agent still on an earlier plug-in version refuses a job type 1.6 backup and runs nothing.
- **When the page shows it:** the Backup page reads stored collections, so a new backup appears within 30 minutes (Last backup) and within an hour (Recovery History) at the default intervals.

### Explain Plan

**Explain Plan** in Statement Detail runs *IBM Db2 - Explain SQL Statement* (`ip_db2_explain_statement`) as the monitoring user, with the target's preferred *IBM DB2 Plug-in Agent Owner Credentials*. Submitting it needs Operator privilege on the target.

- *The explain job could not run. Check that this target has its IBM DB2 Database Monitoring Credentials and preferred IBM DB2 Plug-in Agent Owner Credentials set.* Set both.
- The explain tables are missing, or the monitoring user cannot write them. The plug-in never creates them. A DBA runs `CALL SYSPROC.SYSINSTALLOBJECTS('EXPLAIN', 'C', NULL, NULL)` once, and grants the monitoring user INSERT on the explain tables and SELECT on `EXPLAIN_OPERATOR` and `EXPLAIN_STREAM`.

### Metrics that look wrong

- **Pages look idle, every rate is 0.** A monitor switch is at NONE; see `monitor_switches`.
- **A cache hit ratio reads 100% on an idle database.** A ratio is shown as 100% until 100 lookups have been seen in the interval. Compare it with the lookup count beside it.
- **Wait shares read 0.** While the database spends less than 10 ms per second on requests, the wait shares read 0 by design.
- **A new group has no row yet.** Groups that compute a change between collections write their first row one interval after their first collection; see `pending`.
- **Charts on Last week and Last month look flatter.** Those windows read Enterprise Manager's hourly averages, so peaks look lower than they were.
- **The oldest open transaction is missing a short transaction.** Units of work younger than 5 seconds, and the plug-in's own connections, are left out on purpose.
- **An instance-level alert appears on the instance target and on each of its databases.** Both target types collect the instance-scope groups. Clear those thresholds on the database targets once an instance target exists.
- **An HADR standby shows almost nothing.** Without reads on standby it accepts no connections; see `connection`.

## Versions and platforms

- Supported Db2: 11.5 and 12.1, for Linux, UNIX and Windows, single-partition and partitioned (DPF). pureScale: member and CF health only, implemented and not lab-certified. Db2 for z/OS and Db2 11.1 and earlier are not supported.
- Supported agents: Linux x86-64 and Windows x86-64. AIX, Solaris and HP-UX agents are not supported.
- Enterprise Manager 24ai and 13.5. Each has its own plug-in build: 24.1.x.x.x for 24ai, 13.5.x.x.x for 13.5. Install the build that matches your Enterprise Manager.
- Amazon RDS for Db2, Db2 on OpenShift or Kubernetes (Db2U) and IBM Db2 SaaS are not certified. The agent is always remote there, so the local jobs, Kill and diagnostic-log monitoring are unavailable. On RDS the remote Force Application and Online Backup fail with `SQL1092N`; RUNSTATS works.
- The fix statements are the same on Db2 11.5 and 12.1.

## Where to look

- **CollectorStatus.** The target's `CollectorStatus` metric has one row per metric group: `Status` (`OK`, `NOT_CONFIGURED`, `NOT_COLLECTED_YET`, `NO_DATA`, `COLLECTION_ERROR` or `DISABLED`), a plain-language `Reason`, `ConsecutiveErrors`, `LastDurationMs` and `LastAttemptEpoch`. It tells an empty group from a broken one.
- **The plug-in log** on the agent host that monitors the target: `<agentStateDir>/ip_plugin/xdb2/logging/db2_oem.log`, rotated as `db2_oem-<date>-<n>.log`, up to 10 files of 15 MB. When the agent state directory cannot be used, the log is in the plug-in home instead: `<agent home>/plugins/ip.em.xdb2.agent.plugin_<version>/logging/`.
- **The diagnostics job.** *Collect IBM DB2 Plug-in Diagnostics* (`ip_db2_collect_diagnostics`) gathers the plug-in's logs and state for one target into an archive on the agent host, with secrets written as `<redacted>`. It opens no database connection:

  ```bash
  cat > diag_job.props <<'PROPS'
  name=DB2_Collect_Diagnostics
  type=ip_db2_collect_diagnostics
  target_list=<your_db2_target>:ip_db2_database
  PROPS
  emcli create_job -input_file=property_file:diag_job.props
  ```

  For an instance target use `target_list=<instance target>:ip_db2_instance`. The archive is `<agent state dir>/ip_plugin/xdb2/diagnostics/ip_db2_diagnostics_<target>_<UTC time>.tar.gz`.
- **Enterprise → Job → Activity** for every Kill, backup, Explain and diagnostics run, with its output.
- **The License metric's Status column** for the licence state, and the **License Info** page.

## What to send support

Send these, with passwords, licence keys, keytabs and Kerberos tickets removed:

- The Monitoring Readiness page results: the note under **Check again** (live or stored), and every item with its panel, label, status, current, needs, detail and statement.
- The plug-in version (**Setup → Extensibility → Plug-ins → Databases → IBM DB2 Database**, or `emcli list_plugins_on_server`) and the Enterprise Manager version (24ai or 13.5).
- The Db2 version, the topology (single-partition, DPF or pureScale), and whether the agent runs on the Db2 server.
- The metric group or console page involved, and its `CollectorStatus` row.
- The archive from *Collect IBM DB2 Plug-in Diagnostics*, or the plug-in log.
- For a job, its output from **Enterprise → Job → Activity**.

If a statement or log line contains a secret, replace it with `<removed>` first. Email helpdesk@integrationplumbers.io.

## More help

The human-oriented troubleshooting page: https://docs.integrationplumbers.io/db2/troubleshooting.html

The console pages, including Monitoring Readiness: https://docs.integrationplumbers.io/db2/monitoring-pages.html

Prerequisites, including the monitoring user, TLS and credentials for jobs: https://docs.integrationplumbers.io/db2/prerequisites.html
