---
title: Jobs
nav_order: 11
---

# Jobs

This page describes the twelve Enterprise Manager job types the plug-in adds, the credentials each one runs as, and the housekeeping the plug-in needs on an agent. It is for the Enterprise Manager administrators and DBAs who run, schedule or troubleshoot those jobs.

The jobs fall into four groups: six **local** jobs that run the Db2 command line on the database host; three **remote** admin jobs that run one Db2 command over the target's own JDBC connection, so they work on any target; **Explain SQL Statement**, which shows a cached statement's access plan; and two agent-side jobs for **housekeeping and support**. There is no custom-query metric extension adapter in this release: collecting your own SQL as a metric is not supported.

> **Prerequisites for this page**
> - The six local jobs need the agent **on the same host as the Db2 instance**: see [Network and ports](prerequisites.md#network). They are not available on Amazon RDS for Db2, Db2U or IBM Db2 SaaS.
> - Every job needs one or two [preferred credentials](#credentials) set on the target, and the account differs by job.

**Where to find it:** **Enterprise → Job → Activity → Create Job**. Three console buttons also submit jobs: **Kill** on the [Locks](monitoring-pages.md#locks) and [Sessions](monitoring-pages.md#sessions) pages, **Back Up Database** on the [Backup](monitoring-pages.md#backup) page, and **Explain Plan** in [Statement Detail](monitoring-pages.md#statement-detail).

**In this page:** Jobs shipped with the plug-in · Credentials · The six local jobs · Remote admin jobs · TLS targets · Explain SQL Statement · Corrective action: archive the log when it fills · Purge Stale Plugin Cache · Collect diagnostics for support · Files the plug-in keeps on each agent · Statement metric keys · Running a job

## Jobs shipped with the plug-in {#jobs-shipped}

| Job (display name) | Job type | What it does | Runs |
| :--- | :--- | :--- | :--- |
| Start IBM Db2 Instance | `ip_db2_start_instance` | Starts the Db2 **instance** (`db2start`): every database in it. | Local |
| Stop IBM Db2 Instance | `ip_db2_stop_instance` | Stops the Db2 **instance** (`db2stop force`): every database in it, with every connection forced off. | Local |
| Quiesce IBM Db2 Database | `ip_db2_quiesce_database` | Quiesces the target's database, blocking new connections. | Local |
| Unquiesce IBM Db2 Database | `ip_db2_unquiesce_database` | Removes the quiesced state. | Local |
| Archive IBM Db2 Active Log | `ip_db2_archive_log` | Closes and archives the database's active log (`db2 archive log for database`), online, without disturbing connected applications. Can run as a [corrective action](#corrective-action). | Local |
| Kill IBM Db2 Application | `ip_db2_kill_application` | Forces a specified application off the database (`db2 force application`). Requires an **Application handle** parameter (digits only). Also submitted by **Kill** on Locks and Sessions. | Local |
| IBM Db2 - Force Application (remote) | `ip_db2_admin_force_application` | `FORCE APPLICATION (<handle>)` over `ADMIN_CMD`. | Remote, any target |
| IBM Db2 - RUNSTATS on a Table (remote) | `ip_db2_admin_runstats` | Table, distribution and sampled detailed index statistics for one table. | Remote, any target |
| IBM Db2 - Online Backup (remote) | `ip_db2_admin_backup` | An online backup to a directory on the database server, compressed and with logs unless you say no. Also submitted by **Back Up Database** on Backup, now or on a schedule. | Remote, any target |
| IBM Db2 - Explain SQL Statement | `ip_db2_explain_statement` | Shows the access plan of a statement's cached section. Runs nothing. Also submitted by **Explain Plan** in Statement Detail. | Remote, any target |
| Purge Stale Plugin Cache | `ip_db2_purge_stale_cache` | Deletes the metric-cache files earlier upgrades left in older plug-in homes. Opens no database connection. | Agent-side |
| Collect IBM DB2 Plug-in Diagnostics | `ip_db2_collect_diagnostics` | Writes one archive of the plug-in's logs and environment for support. Opens no database connection. | Agent-side |

**Four of them also run from an IBM Db2 Instance target** ([Instance targets](targets-and-properties.md#instance-targets)): Start and Stop IBM Db2 Instance, whose natural home is the instance and which offer the instance target type first, plus Purge Stale Plugin Cache and Collect IBM DB2 Plug-in Diagnostics. They behave the same from either target type, and jobs saved against a database target keep working. The other jobs act on one database and run only from a database target.

The job types were renamed for GA; the earlier `sidb_*` and beta `sidbb_*` names are gone: see [Breaking changes](whats-new.md#breaking-changes).

## Credentials {#credentials}

Each job runs as a specific account, held in a **preferred credential** set on the target. Set them under **Setup → Security → Preferred Credentials → IBM Db2 Database** (or **IBM Db2 Instance**), choosing the set and then the target, or with EM CLI:

```bash
emcli set_preferred_credential -set_name=<set name> -target_type=ip_db2_database \
      -target_name=<target> -credential_name=<named credential>
```

| Preferred credential set | Set name | Holds | Used by |
| :--- | :--- | :--- | :--- |
| IBM DB2 Database Host Credentials | `DB2HostCreds` | The Db2 instance owner's OS account on the Db2 host | The six local jobs, including Kill and the archive-log corrective action |
| IBM DB2 Plug-in Agent Owner Credentials | `DB2AgentOwnerCreds` | The account that owns the agent installation (commonly `oracle`) | Purge Stale Plugin Cache, Collect IBM DB2 Plug-in Diagnostics, the three remote jobs and Explain SQL Statement |
| IBM DB2 Database Admin Credentials | `DB2AdminCreds` | A Db2 admin user (a database credential) | The three remote jobs |
| IBM DB2 Database Monitoring Credentials | `DB2DatabaseMonitoringCreds` | The monitoring user | Explain SQL Statement only |

On an IBM Db2 Instance target, the start and stop jobs use the instance target's own **IBM Db2 Instance Host Credentials** (set `DB2HostCreds`, the instance owner) and the housekeeping jobs its `DB2AgentOwnerCreds`:

```bash
emcli set_preferred_credential -set_name=DB2HostCreds -target_type=ip_db2_instance \
      -target_name=<instance target> -credential_name=<named credential>
```

Only Explain uses the monitoring user. The remote jobs need **both** the admin and the agent owner sets: Enterprise Manager has no optional credential, so a job fails at once, before it connects, if either is missing.

## The six local jobs {#local-jobs}

The local jobs run the Db2 command line on the database host as the instance owner, through **IBM DB2 Database Host Credentials**. The agent must be on the same host as the Db2 instance, so they are unavailable on managed services such as Amazon RDS for Db2: see [Troubleshooting](troubleshooting.md#rds-for-db2).

- **The local-only rule is enforced.** Each job reads the target's `local` property, which the plug-in sets by comparing the Db2 host with the agent host. Unless `local` is 1, the job fails at once with `ERROR: refusing to run: this job acts on the Db2 instance on the agent's own host…`, and nothing runs. A remotely monitored target's agent host may run a *different* Db2 instance, which the job would otherwise act on.
- **Start and Stop act on the whole instance.** Every database in the instance is affected, not just the target you selected, and Stop also forces off every connection. Both display names say so. While the instance is stopped, its database targets and the instance target all read Down, as expected.
- **Parameters are validated** before any command is built. The application handle must be digits.
- **On Linux, the instance owner must be able to read the agent's plug-in files.** The agent installs them readable only by the agent install owner and that owner's group. If the instance owner is not in that group, every job fails at once with `Can't open perl script ".../killagent.pl": Permission denied`. Add the instance owner to the agent install owner's group on the Db2 host, then submit the job again. No agent restart is needed:

  ```bash
  usermod -aG <agent install group> db2inst1      # for example oinstall
  ```

**The Kill buttons on Locks and Sessions use preferred credentials.** They submit the job without asking for any, so set the target's **IBM DB2 Database Host Credentials** first (`-set_name=DB2HostCreds` in the command above). Without them, the button reports *The kill job could not run. Check that preferred host credentials are set for this target.* Jobs created under **Enterprise → Job → Activity** use the same preferred credentials, or take explicit ones at submission. Every kill stays in **Enterprise → Job → Activity** as an audit record.

**Archive IBM Db2 Active Log** is the only way the plug-in archives the log on its own: the remote jobs cannot, because `ADMIN_CMD` does not accept `ARCHIVE LOG`. It reads the database name from the target and takes no parameter. The instance owner needs SYSADM, SYSCTRL, SYSMAINT or DBADM.

## Remote admin jobs {#remote-admin-jobs}

The three remote jobs do not need the agent on the database host. Each runs one Db2 command over `SYSPROC.ADMIN_CMD` on the target's own JDBC connection, as the user in **IBM DB2 Database Admin Credentials**, never the monitoring user, so they work on a remotely monitored target too.

| Job (display name) | Job type | Db2 command | Parameters | Authority (any one) |
| :--- | :--- | :--- | :--- | :--- |
| IBM Db2 - Force Application (remote) | `ip_db2_admin_force_application` | `FORCE APPLICATION (<handle>)` | Application Handle (digits) | SYSADM, SYSCTRL, SYSMAINT |
| IBM Db2 - RUNSTATS on a Table (remote) | `ip_db2_admin_runstats` | `RUNSTATS ON TABLE <schema>.<table> WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL` | Schema, Table (undelimited names) | DBADM, SQLADM, DATAACCESS, or CONTROL or LOAD on the table |
| IBM Db2 - Online Backup (remote) | `ip_db2_admin_backup` | `BACKUP DATABASE <db> ONLINE TO <directory> [COMPRESS] INCLUDE LOGS`, or `EXCLUDE LOGS` | Backup Directory (absolute path on the database server); Compress the Backup Image and Include Logs (`yes` or `no`, both `yes` by default, also when left empty) | SYSADM, SYSCTRL, SYSMAINT |

The backup job type is version **1.6**. A job saved under an earlier version has no Compress or Include Logs value and runs as before: compressed, with logs. With `emcli create_job`, `variable.backup_path` alone is enough. **Deploy the plug-in to the agents as well as the OMS:** an agent still on the previous version refuses a 1.6 backup job (`STDIN names DB_BACKUP_COMPRESS`) and runs nothing.

### The admin user {#admin-user}

- **It also needs `EXECUTE` on `SYSPROC.ADMIN_CMD`.** SYSADM, SYSCTRL and SYSMAINT have it implicitly. For anyone else:

  ```sql
  GRANT EXECUTE ON PROCEDURE SYSPROC.ADMIN_CMD TO USER <admin user>;
  ```

- **The backup job also needs `EXECUTE` on `SYSPROC.DB_MEMBERS`**, because it counts the database partitions with it before `BACKUP`. SYSADM, SYSCTRL and SYSMAINT do not cover it. `PUBLIC` holds it on a database that was not created `RESTRICTIVE`. Elsewhere (every Amazon RDS for Db2 database is RESTRICTIVE), grant it, or give the admin user SQLADM:

  ```sql
  GRANT EXECUTE ON FUNCTION SYSPROC.DB_MEMBERS TO USER <admin user>;
  ```

- **A least-privilege admin user for all three** is a member of the instance's `SYSMAINT_GROUP` with `SQLADM`. That group can force applications and back up the database, and with `SQLADM` it can run RUNSTATS and read the partition count. Unlike SYSADM, it cannot change configuration or data. Set the group with `db2 update dbm cfg using SYSMAINT_GROUP <group>` and add the user to that operating-system group on the database server; grant `SQLADM` in the database with `GRANT SQLADM ON DATABASE TO USER <admin user>`.
- **The force job checks the handle first, if it can.** `FORCE APPLICATION` accepts any number, so a mistyped handle would look like a success. When the admin user can read `MON_GET_CONNECTION` (`SQLADM`, or `EXECUTE` on that function), the job refuses a handle that is not connected. Without that privilege the force runs anyway, and its output says the handle was not checked.

### Before the first run {#before-first-run}

1. Set **IBM DB2 Database Admin Credentials** on the target: a named credential of type **IBM DB2 Database Credentials** holding the admin user (`-set_name=DB2AdminCreds` in the command above).
2. Set **IBM DB2 Plug-in Agent Owner Credentials** on the target: the agent install owner, who can read the plug-in's files (`-set_name=DB2AgentOwnerCreds`).
3. On a TLS target, set its client truststore credential set too: see [TLS targets](#tls-targets).

A job with either credential missing fails at once with `Default preferred credentials are not set`, and never falls back to the monitoring user. Submitting the jobs needs **Full** privilege on the target, because the job runs as the admin user stored on it.

**Every value is checked before anything runs.** Schema and table must be plain Db2 names; the directory must be an absolute path with no spaces, quotes or commas; anything else is refused with a message naming the field. A parameter that contains a line break is refused before the job connects (`refusing to run <job>`), so a value submitted through EM CLI or the REST API cannot add connection settings of its own. A refused value or a Db2 error fails the job, and the job output carries Db2's own message.

### Backup {#backup-job}

- **Online only, and it needs archive logging** (`LOGARCHMETH1` not `OFF`). The backup directory is on the **database server**, not the agent host, and must exist and be writable by the instance owner. Offline backups are not offered.
- **Refused on a partitioned (DPF) database, however it was submitted** (the Backup page, the Job Library, `emcli create_job`, a saved or scheduled job). Without `ON ALL DBPARTITIONNUMS` it would back up only the partition its connection runs on, and that image cannot restore the database. Before `BACKUP`, the job counts the database partitions on its own connection and, for more than one, fails with a sentence naming DPF and `ON ALL DBPARTITIONNUMS` and runs nothing. If it cannot read the count it refuses too, and when Db2 refused the read for authorization the refusal names the `GRANT` above. Single-partition and pureScale databases back up as before. Back up a DPF database on the server with `ON ALL DBPARTITIONNUMS`.
- **Db2 deletes no image by itself** unless `AUTO_DEL_REC_OBJ` is on, so a recurring backup fills its directory until that setting or your own housekeeping removes old images.
- **A new backup appears on the Backup page after the next collections**: within 30 minutes for the last backup and an hour for the history, at the default intervals.

The job's failures carry one plain sentence before Db2's own message:

| Db2 code | What it means |
| :--- | :--- |
| `SQL2413N` | Online backup needs archive logging and no backup pending |
| `SQL1116N` | The database is in backup pending; only an offline backup on the server clears it |
| `SQL2036N` | The directory does not exist on the database server, or is not writable by the instance owner |
| `SQL2061N` | Db2 was denied access to the directory |
| `SQL2419N` | The disk holding the directory filled up |
| `SQL1092N` | The admin user lacks SYSADM, SYSCTRL or SYSMAINT (on Amazon RDS for Db2 no user can hold them: use RDS backups or `rdsadmin.backup_database`) |
| `SQL0551N` | The admin user lacks a privilege, most often EXECUTE on `SYSPROC.ADMIN_CMD`, or on `SYSPROC.DB_MEMBERS` for the partition count |

**Amazon RDS for Db2:** RUNSTATS works, over the plain port and over TLS with the RDS CA in the target's client truststore. Force Application and Online Backup fail with `SQL1092N`, because no RDS user holds SYSADM, SYSCTRL or SYSMAINT. Enterprise Manager still offers both jobs. Use RDS's own backups, or `rdsadmin.backup_database` to Amazon S3.

## TLS targets {#tls-targets}

A target with **Use SSL/TLS?** set to `yes` runs the remote jobs and Explain over TLS with its own **Client Truststore**: the *IBM DB2 Client Truststore Monitoring Credentials*, the same location, type and password its metrics use. The job reads them from that credential set when it runs.

- The truststore file must be readable on the agent host by the *IBM DB2 Plug-in Agent Owner Credentials* user, and its location must be an absolute path. A location or type that fails the check is refused before the job connects, and the message names the location.
- The truststore password goes to the job on its standard input, never on a command line, and is never printed.
- **A `yes` target needs the truststore credential set, even when it trusts the agent JVM's default `cacerts`.** Enterprise Manager fails the job at once when it is missing ("Unable to resolve credential reference" or "Default preferred credentials are not set"). For a server certificate the JVM already trusts, point the truststore credential at the agent JVM's own `cacerts`: the location `<agent JDK>/jre/lib/security/cacerts` (`<agent JDK>/lib/security/cacerts` on JDK 9 or later), the type `keytool -list -keystore <that file>` reports (`JKS` on the agent's JDK 8), and its store password (`changeit` unless the agent's JDK was changed). EM CLI does not store an empty truststore password: `set_monitoring_credential` prompts for one. [The OMS settings](targets-and-properties.md#oms-settings) say how to find the JDK the agent runs the plug-in on.
- The jobs recognise `yes`, `YES` and `Yes`. Any other value the collector accepts as yes (`true`, `y`, `1`, `on`) still connects over TLS, but against the agent JVM's default trust store. Use `yes`.

## Explain SQL Statement {#explain}

**IBM Db2 - Explain SQL Statement** (`ip_db2_explain_statement`) shows the access plan Db2 is using for one statement. Start it from **SQL → Top Statements**: open a statement, then click **Explain Plan** in Statement Detail. The plan appears in the dialog when the job finishes, usually within a minute. Each run is also kept under **Enterprise → Job → Activity**, and the job can be submitted from there with the **Statement Hash** shown in the dialog.

**What it does.** The job finds the statement's section in Db2's package cache and explains that section with `SYSPROC.EXPLAIN_FROM_SECTION`. The statement is not run, and its text is not compiled again, so the plan is the one Db2 actually used. The job reads the plan back from the explain tables and then rolls back, so it leaves no rows in them. It runs on any target, local or remote, as the **monitoring user**, and authenticates to the agent host with the *IBM DB2 Plug-in Agent Owner Credentials*. Submitting it needs **Operator** privilege on the target.

The dialog shows, for each operator from the top down: the operator (for example `RETURN`, `NLJOIN`, `TBSCAN`, `IXSCAN`), the estimated rows it passes up, its cumulative cost and I/O cost in timerons, and the table or index it reads or writes. Above the table: the statement's estimated total cost and how often the cached section has run.

**Setup, once per database.** A DBA does this; the plug-in never creates database objects. Connected to the database as a user with DBADM or SYSADM:

```sql
-- 1. Create the explain tables in schema SYSTOOLS (table space SYSTOOLSPACE).
CALL SYSPROC.SYSINSTALLOBJECTS('EXPLAIN', 'C', NULL, NULL);

-- 2. Let the monitoring user write the plan: generate one GRANT per explain table, then run the output.
SELECT 'GRANT INSERT ON SYSTOOLS.' || TABNAME || ' TO USER OEM_MONITOR;'
  FROM SYSCAT.TABLES
 WHERE TABSCHEMA = 'SYSTOOLS' AND (TABNAME LIKE 'EXPLAIN!_%' ESCAPE '!' OR TABNAME = 'OBJECT_METRICS');

-- 3. Let it read the plan back.
GRANT SELECT ON SYSTOOLS.EXPLAIN_OPERATOR TO USER OEM_MONITOR;
GRANT SELECT ON SYSTOOLS.EXPLAIN_STREAM   TO USER OEM_MONITOR;
```

Replace `OEM_MONITOR` with your monitoring user. Instead of `SYSTOOLS`, the tables can be in the monitoring user's own schema: Db2 looks there first, then in `SYSTOOLS`. Either pass that schema as the fourth argument of `SYSINSTALLOBJECTS` and grant the same privileges on it, or run `db2 -tf ~/sqllib/misc/EXPLAIN.DDL` as the monitoring user, which then owns the tables and needs no grants. EXECUTE on `SYSPROC.EXPLAIN_FROM_SECTION` is already covered by the monitoring user's `SQLADM`.

**When it cannot explain, the dialog says why.**

| Message starts | Cause | What to do |
| :--- | :--- | :--- |
| *The Db2 explain tables are not set up for …* | No `EXPLAIN_INSTANCE` table in the monitoring user's schema or `SYSTOOLS` (`SQL0219N`) | The setup above |
| *The Db2 explain tables were created by an older Db2 level …* | `SQL0220N` after a Db2 upgrade | `CALL SYSPROC.SYSINSTALLOBJECTS('EXPLAIN', 'M', NULL, NULL)` |
| *… lacks a privilege EXPLAIN needs …* | `SQL0551N` | The grants above |
| *Statement … is not in the Db2 package cache now …* | Db2 has dropped the statement from its package cache (it needed the room, or the database restarted) | Run the statement again, then explain it |
| *The explain job could not run …* | A credential set is missing on the target | Set the monitoring credentials and the preferred *IBM DB2 Plug-in Agent Owner Credentials* |

**Limitations.** The section must still be in the package cache, so a statement that ran once, long ago, may have left it. When one statement text has several sections in the cache, the job explains the most-executed one and says how many there were. On a TLS target the job uses the target's client truststore, with the same rules as the remote jobs ([TLS targets](#tls-targets)).

## Corrective action: archive the log when it fills {#corrective-action}

An administrator can have Enterprise Manager run **Archive IBM Db2 Active Log** by itself when a target's **Log Space Utilization (%)** alert goes Critical. That makes it a *corrective action*.

**It is off until you turn it on.** The plug-in ships no corrective action: nothing runs on any target until an administrator creates the library entry below and attaches it to a target's alert, and it runs only on the targets it is attached to.

**What it does when the alert fires.** Enterprise Manager runs the job once, on the target's agent, when the alert's severity becomes Critical. The shipped threshold is above 85% for three consecutive collections, and Log_Storage is collected every 30 minutes, so the alert comes about an hour after the first reading above 85%. The job does not run again on every collection while the alert stays Critical.

1. The job checks that the agent is on the target's own Db2 host (`local` is 1), as every local job does. On a remotely monitored target it fails at once with `refusing to run`, and nothing runs.
2. It reads the database's logging configuration (`db2 get db cfg`), as the instance owner.
3. **Circular logging** (`LOGARCHMETH1` and `LOGARCHMETH2` both `OFF`): it runs nothing and **succeeds**, with the output *Nothing to archive: database … uses circular logging …*. Db2 itself refuses `ARCHIVE LOG` there (`SQL2417N`), and reuses circular log files by itself, so on such a database a full log is held by an open transaction.
4. **Archive logging** (any other method, including `LOGRETAIN`): it runs `db2 archive log for database <the target's database>`. That closes the active log file and archives it, online. If the configuration could not be read, the job still runs `ARCHIVE LOG` and lets Db2 answer. Running it again is harmless.

**What it cannot fix.** Archiving frees log space only once no open transaction still needs that log. When one long transaction holds the log, archiving does not help. The [Transaction Log](monitoring-pages.md#transaction-log) page and the *IBM DB2: Transaction Log Filling* [runbook](alerts-and-templates.md#runbooks) name the application holding the oldest transaction, and ending that transaction is a decision for you.

**Before you attach it:** attach it only on targets whose agent runs on the Db2 server (`local` = 1); set the target's preferred **IBM DB2 Database Host Credentials** to the instance owner, as for Kill; and on Linux, put the instance owner in the agent install owner's group ([The six local jobs](#local-jobs)).

### Create the library entry (once per OMS)

1. **Enterprise → Monitoring → Corrective Actions**.
2. In **Create Library Corrective Action**, choose **Archive IBM Db2 Active Log**, then click **Go**. The list can also show older Db2 job types from other or earlier plug-ins (for example *Kill DB2 Application* or *Quiesce IBM DB2 DB*). Pick only **Archive IBM Db2 Active Log**.
3. On the **General** tab, enter a **Name** such as `IP Db2 - archive active log` (Enterprise Manager stores it in upper case, as *IP DB2 - ARCHIVE ACTIVE LOG*) and a **Description**, and under **Event Types** select **Metric Alert**. Leave **Automatic Attempts** at `<none>`. **Target Type** is already IBM Db2 Database.
4. **Parameters:** the page says *This job does not require any parameters.*
5. **Credentials:** for **defaultHostCred**, leave **Preferred Credential Name** at **IBM DB2 Database Host Credentials**. Do not enter a user name and password here.
6. **Access:** grant **View** to the administrators who will attach it.
7. Click **Save to Library**. The entry is saved as **Draft**.
8. Select the entry, click **Publish**, then click **Yes**. A Draft entry is not offered when you attach it from the library.

### Attach it to a target's log alert

1. On the target's home page, choose **Monitoring → Metric and Collection Settings** from the target menu.
2. On the **Metrics** tab, find **Log Space Utilization (%)** under **Log Storage**, and click its **Edit** (pencil) icon.
3. Log Space Utilization is kept per database, so **Edit Advanced Settings** first shows a **Monitored Objects** table. Select **All others**, or the row for one database, then click **Edit**.
4. In **Corrective Actions**, click **Add** on the **Critical** row.
5. Leave **Add Corrective Action** at **From Library...**, select *IP DB2 - ARCHIVE ACTIVE LOG*, then click **Continue**.
6. Under **Credential**, leave **Preferred**, with **IBM DB2 Database Host Credentials**, then click **Continue**.
7. Select **Allow only one corrective action for this metric to run at any given time**. It is not selected by default.
8. Click **Continue** twice, then click **OK** on **Metric and Collection Settings**. The page reports *Update succeeded*.

To do this for many targets, add the same corrective action to the Log Space Utilization (%) threshold of a monitoring template, and apply the template to targets with `local` = 1 only. Enterprise Manager has no EM CLI verb that creates or attaches a metric corrective action, so use the console. You can still run the job itself with `emcli create_job` and `type=ip_db2_archive_log`, for example to try it on one target first.

**See it run.** Each run is a job named after the corrective action under **Enterprise → Job → Activity**, and the event in **Incident Manager** shows its corrective-action status. The job output says whether it archived the log (*DB20000I The ARCHIVE LOG command completed successfully.*), found *Nothing to archive*, or refused to run on a remote agent. A *Succeeded* run that says *Nothing to archive* changed nothing, so the alert stays Critical until the open transaction ends.

**Remove it** from the same per-object **Edit Advanced Settings** page: on the **Critical** row of **Corrective Actions**, click **Remove**, then **Continue** twice and **OK**. If a monitoring template attached it, remove it from the template too, or the next apply attaches it again. To retire the library entry, remove every attachment first (the **References** column shows how many remain), then select it under **Enterprise → Monitoring → Corrective Actions** and click **Delete**.

## Purge Stale Plugin Cache {#purge-stale-cache}

**Run it once after upgrading from GA (24.1.1.0.0 / 13.5.2.0.0), or schedule it.** It is housekeeping, not a fix: skipping it wastes a small amount of disk and nothing else.

**Why it is needed.** Several metrics are deltas: they report the change since the previous collection. To compute them, the agent keeps a small cache file per target, which also holds the CollectorStatus history. GA kept that file inside the **versioned plug-in home**, and an upgrade creates a new home, so each earlier version's cache files are stranded: a few KB per target, per version.

**From 24.1.2.0.0 / 13.5.3.0.0** the cache lives in the agent state directory instead (`<agentStateDir>/ip_plugin/xdb2/cache/`, see [Files the plug-in keeps on each agent](#agent-files)), which an upgrade does not touch. The first collection after the upgrade copies the CollectorStatus history from the previous version's home, and this job then removes the old file. Once every older home has been swept, the job finds nothing to do.

**Why it is not automatic.** Enterprise Manager provides no post-deployment or upgrade hook for a plug-in. A scheduled job is the supported equivalent.

**Run it once, from the console:** **Enterprise → Job → Activity → Create Job**, choose **Purge Stale Plugin Cache**, and select any one Db2 target on the agent you want cleaned. The sweep covers that whole agent, so one target per agent is enough.

**Or schedule it.** The sweep is idempotent: it deletes only files that are already dead and does nothing when there is nothing stale, so a weekly job costs nothing between upgrades:

```bash
cat > purge_job.props <<'PROPS'
name=DB2_Purge_Stale_Cache
type=ip_db2_purge_stale_cache
target_list=<your_db2_target>:ip_db2_database
schedule.frequency=WEEKLY
schedule.startTime=<YYYY-MM-DD> 03:00
schedule.days=1
PROPS

emcli create_job -input_file=property_file:purge_job.props
```

`emcli create_job` takes a property file and has no `-target_list`, `-job_type` or `-schedule` flags. Add `-preview` to have Enterprise Manager describe the job it would create without creating it: the quickest way to check a property file, and it reports an unrecognised property name rather than ignoring it.

**Credentials: the one thing that catches people out.** The job needs host credentials for the account that **owns the agent installation** (commonly `oracle`), held in **IBM DB2 Plug-in Agent Owner Credentials**, not the Db2 instance owner the local jobs use. The plug-in's agent-side files are not world-readable, so a credential for any other OS user authenticates and then cannot read the job's script. A user who can read them but does not own them (for example the Db2 instance owner, once it is in the agent group) runs the job but cannot delete the files, and the job fails with `Deleted 0 of N orphaned cache file(s); N could not be removed`. On Windows that message can also mean a file is in use: run the job again later. If the set is not configured, the job fails at once with `Unable to get credentials for defaultHostCred`. To supply a credential explicitly instead:

```
cred.defaultHostCred.<target_name>:ip_db2_database=NAMED:<host_credential_name>
```

### What it will and will not delete

| Situation | Behaviour |
| :--- | :--- |
| Older plug-in homes from past upgrades | Cache files deleted. This is the case the job exists for. |
| The live cache in the agent state directory | **Never touched.** The job sweeps plug-in homes only. |
| The current plug-in home | **Never touched.** The job derives its prefix from its own home and sweeps only siblings, so your live delta metrics cannot be broken by running it. |
| Other plug-ins' directories | Never touched, for the same reason. |
| An unrecognised directory layout | Deletes nothing, rather than guessing. |
| A target you deleted | Its cache file in the agent state directory is left in place. It is inert; delete it by hand if you like ([Files the plug-in keeps on each agent](#agent-files)). |
| Plug-in undeployed | Undeploy does not remove older plug-in homes or the agent state directory: see [Files the plug-in keeps on each agent](#agent-files). |

**Is it safe to run at any time?** Yes. It opens no database connection, it cannot touch the live cache, and a file it cannot delete is logged and skipped rather than aborting the sweep.

## Collect diagnostics for support {#collect-diagnostics}

When support asks for diagnostics, run **Collect IBM DB2 Plug-in Diagnostics** against the target. It reads files on the target's agent only and opens no database connection, so it works whether the agent is on the Db2 host or not. It writes one archive and prints its path in the job output:

```
<agent state dir>/ip_plugin/xdb2/diagnostics/ip_db2_diagnostics_<target>_<UTC time>.tar.gz
```

The archive holds the plug-in's own log files (the newest five, up to 50 MB), the target's metric cache, an environment report (plug-in version, the JVM the collector uses, the classpath, and the IBM JDBC driver version), and the target's properties from the agent's `targets.xml`.

**Nothing secret is included.** The monitoring credential, the truststore password, the OMS credential, and any property marked encrypted or named like a password, key, secret or token are written as `<redacted>`. The licence key shows only as its length. The archive is readable by the agent owner only, and the newest five archives are kept. The job uses the same agent owner credentials as Purge Stale Plugin Cache. From the command line:

```bash
cat > diag_job.props <<'PROPS'
name=DB2_Collect_Diagnostics
type=ip_db2_collect_diagnostics
target_list=<your_db2_target>:ip_db2_database
PROPS
emcli create_job -input_file=property_file:diag_job.props
```

From an IBM Db2 Instance target, use `target_list=<instance target>:ip_db2_instance`. The archive then holds that target's properties and cache.

## Files the plug-in keeps on each agent {#agent-files}

**Where the plug-in writes.** The plug-in home on an agent (`<agent home>/plugins/ip.em.xdb2.agent.plugin_<version>`) holds only the files Enterprise Manager installed. From 24.1.2.0.0 / 13.5.3.0.0, everything the plug-in writes while it runs goes to its own directory in the agent state directory (`agentStateDir`, usually the agent's `agent_inst`), owned by the agent install user:

| Path under `<agentStateDir>/ip_plugin/xdb2/` | What it is | Written by |
| :--- | :--- | :--- |
| `cache/IBM Db2 Database-<target>.ser` (and `.ser.lock`) | The target's metric cache: delta baselines, the licence count, and the CollectorStatus history | Every collection |
| `cache/IBM Db2 Database-<target>.ser.<group>.skip` | A record of a collection the agent-load throttle skipped | The [throttle](prerequisites.md#collection-throttle), when configured |
| `logging/db2_oem.log` (and rotated `db2_oem-<date>-<n>.log`, up to 10 of 15 MB) | The plug-in's log | Collections and plug-in jobs |
| `lib/` | Where support may ask you to place an IBM `db2jcc*.jar`; normally empty | The first collection creates it |
| `diagnostics/` | Archives from the diagnostics job (newest five) | [Collect diagnostics](#collect-diagnostics) |
| `batch/` | The batch-collection helpers' files, when [batch collection](prerequisites.md#batch-collection) is on | The helpers |
| `collection-throttle.conf`, `krb5.conf`, `jaas.conf` | Configuration you place there yourself | You |

In a cache file name, a character of the target name that a file name cannot hold (`/ \ : * ? " < > |`), and `%`, is written as `%` and its hex code: target `db2host/SAMPLE` has `IBM Db2 Database-db2host%2FSAMPLE.ser`. Before this release the target type was spelled *IBM DB2 Database*; the first collection after the upgrade renames the cache file, so the CollectorStatus history is kept.

If the agent has no `agentStateDir`, or the plug-in cannot create or write those directories, it keeps the cache and the log in the plug-in home as earlier releases did.

**What a full undeploy leaves behind.** Enterprise Manager has no uninstall hook for a plug-in, so after you undeploy the plug-in from every agent and then from the OMS, these remain: every older plug-in home on each agent (`<agent home>/plugins/ip.em.xdb2.agent.plugin_*`); the plug-in's agent state directory, `<agentStateDir>/ip_plugin/xdb2/`; and older plug-in homes on the OMS, with their Oracle inventory records. Leave the OMS ones: only an Oracle-supported detach should change them.

**To clean an agent**, after the plug-in is undeployed from it (check with `emcli list_plugins_on_agent -agent_names=<host>:<port>`: no `ip.em.xdb2` row), run as the agent install owner:

```bash
rm -rf <agent home>/plugins/ip.em.xdb2.agent.plugin_*
rm -rf <agentStateDir>/ip_plugin/xdb2
```

On Windows:

```
for /d %d in (<agent home>\plugins\ip.em.xdb2.agent.plugin_*) do rmdir /s /q "%d"
rmdir /s /q <agentStateDir>\ip_plugin\xdb2
```

Keep a copy of `collection-throttle.conf`, `krb5.conf` or `jaas.conf` first if you will reinstall. **While the plug-in is still deployed**, do not delete `ip_plugin/xdb2/`: it holds the live cache and the CollectorStatus history. You may remove only plug-in homes whose version differs from the one `emcli list_plugins_on_agent` reports, and the cache file of a target you deleted.

## Statement metric keys {#statement-keys}

Enterprise Manager stores one *metric key* per row identity of a keyed metric group. For the SQL page's groups (`Query_Analytics`, `Statement_Text`) the key is the statement. Enterprise Manager keeps a key until 24 months after it last reported, and reading a window of a keyed group costs a lookup for every key the target has ever had, not only the ones in the window.

Before 24.1.2.0.0 / 13.5.3.0.0 the statement key was the exact SQL text, so every literal value made a new key, and a busy target could build up tens of thousands of them. The plug-in now keys statements by digest (literals replaced by `?`), and adds at most 200 new statement keys per target in any 24 hours. Nothing needs doing on a target added with this release.

**Upgraded targets** keep the keys they already have. They stop growing, and Enterprise Manager purges them 24 months after they last reported. A window that reaches back before the upgrade shows a statement twice: the old literal-text rows and the new digest row. Integration Plumbers supplies a read-only SQL report, `db2_metric_keys_report.sql`, beside the plug-in, that shows how many keys each target carries. For a target whose SQL page is slow, and whose `Query_Analytics` row in that report shows a `dead_ratio` of 10 or more, choose one of:

- **Wait.** Enterprise Manager's purge removes the old keys on its own.
- **Recreate the target.** Delete it and add it again with the same properties and credentials ([Add a target with EM CLI](targets-and-properties.md#add-target-emcli); `emcli get_target_properties` shows the current values first). This drops the target's collected history, alerts and old keys at once.
- **Shorten Enterprise Manager's daily-rollup retention** with `gc_interval_partition_mgr.set_retention`, as the Enterprise Manager Administrator's Guide describes under "Modifying the Default Aggregation and Purging Policies". It affects every target type on the OMS, and drops all daily history older than the new retention, so it is an OMS-wide decision, not a plug-in setting.

Never delete rows from `SYSMAN` tables yourself.

## Running a job {#running-a-job}

1. **Enterprise → Job → Activity → Create Job**.
2. Choose the job type from the table above.
3. Add the target to run it against, and give the job a meaningful name.
4. Enter the job's parameters: the **Application handle** for the kill and force jobs, the schema and table for RUNSTATS, the backup directory (and Compress and Include Logs) for the backup, the statement hash for Explain.
5. Confirm the credentials tab shows the right account: see [Credentials](#credentials) for which job needs which.
6. Submit, then track it from **Enterprise → Job → Activity** like any other Enterprise Manager job.

## Related

- [Prerequisites](prerequisites.md#preferred-credentials): the credential sets, alongside the other prerequisites
- [Monitoring pages](monitoring-pages.md#backup): **Back Up Database**, **Kill** on Locks and Sessions, and **Explain Plan** in Statement Detail
- [Alerts and templates](alerts-and-templates.md#runbooks): the runbooks for the most common Db2 alerts
- [Install and upgrade](install-and-upgrade.md#after-upgrade): what to run after an upgrade
- [Troubleshooting](troubleshooting.md#jobs): job failures by the message you see
