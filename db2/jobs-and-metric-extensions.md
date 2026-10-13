---
title: Jobs
nav_order: 11
---

# Jobs

The plug-in adds Enterprise Manager job types for the `ip_db2_database` target in three groups: five **local** administrative jobs that run the Db2 command line on the database host; three **remote** administrative jobs that run one Db2 command over the target's own JDBC connection, so they work on any target; and two agent-side jobs for **housekeeping and support**. There is no custom-query metric extension adapter in this release — if your site needs to collect its own SQL as a metric, that is not supported.

> **Prerequisites for this page**
> - The five local jobs need the agent **co-located on the same host as the Db2 instance** — see [Network and ports](prerequisites.md#network). They are not available for cloud-managed databases such as Amazon RDS for Db2.
> - Every job needs one or two [preferred credentials](#credentials) set on the target, and the account differs by job.

**Where to find it:** **Enterprise → Job → Activity → Create Job**; the Kill IBM Db2 Application job also runs from the **Kill Blocking Application** button on the target's **Analysis** page.

**In this page:** Jobs shipped with the plug-in · Credentials · The five local jobs · Remote admin jobs · Purge Stale Plugin Cache · Collect diagnostics for support · Running a job

## Jobs shipped with the plug-in

| Job (display name) | Job type | What it does | Runs |
| :--- | :--- | :--- | :--- |
| Start IBM Db2 Instance | `ip_db2_start_instance` | Starts the Db2 **instance** (`db2start`): every database in it. | Local |
| Stop IBM Db2 Instance | `ip_db2_stop_instance` | Stops the Db2 **instance** (`db2stop force`): every database in it, with every connection forced off. | Local |
| Quiesce IBM Db2 Database | `ip_db2_quiesce_database` | Quiesces the target's database, blocking new connections. | Local |
| Unquiesce IBM Db2 Database | `ip_db2_unquiesce_database` | Removes the quiesced state. | Local |
| Kill IBM Db2 Application | `ip_db2_kill_application` | Forces a specified application off the database (`db2 force application`). Requires an **Application handle** parameter (digits only). Also submitted by the **Kill Blocking Application** button on [Analysis](monitoring-pages.md#analysis). | Local |
| IBM Db2 - Force Application (remote) | `ip_db2_admin_force_application` | `FORCE APPLICATION (<handle>)` over `ADMIN_CMD`. | Remote, any target |
| IBM Db2 - RUNSTATS on a Table (remote) | `ip_db2_admin_runstats` | Table, distribution and sampled detailed index statistics for one table. | Remote, any target |
| IBM Db2 - Online Backup (remote) | `ip_db2_admin_backup` | An online, compressed backup with logs, to a directory on the database server. | Remote, any target |
| Purge Stale Plugin Cache | `ip_db2_purge_stale_cache` | Deletes the metric-cache files a previous upgrade left behind in an older plug-in home. Opens no database connection. | Agent-side |
| Collect IBM DB2 Plug-in Diagnostics | `ip_db2_collect_diagnostics` | Writes one archive of the plug-in's logs and environment for support. Opens no database connection. | Agent-side |

The job types were renamed for GA; the earlier `sidb_*` and beta `sidbb_*` names are gone — see [Breaking changes](whats-new.md#breaking-changes).

## Credentials {#credentials}

Each job runs as a specific account, held in a **preferred credential** set on the target. Set them under **Setup → Security → Preferred Credentials → IBM DB2 Database**, choosing the set and then the target, or with EM CLI:

```bash
emcli set_preferred_credential -set_name=<set name> -target_type=ip_db2_database \
      -target_name=<target> -credential_name=<named credential>
```

| Preferred credential set | Set name | Holds | Used by |
| :--- | :--- | :--- | :--- |
| IBM DB2 Database Host Credentials | `DB2HostCreds` | The Db2 instance owner's OS account on the Db2 host | The five local jobs |
| IBM DB2 Plug-in Agent Owner Credentials | `DB2AgentOwnerCreds` | The account that owns the agent installation (commonly `oracle`) | Purge Stale Plugin Cache, Collect IBM DB2 Plug-in Diagnostics, and the three remote jobs |
| IBM DB2 Database Admin Credentials | `DB2AdminCreds` | A Db2 admin user (a database credential) | The three remote jobs |

None of the jobs uses the monitoring user. The remote jobs need **both** the admin and the agent owner sets: Enterprise Manager has no optional credential, so a job fails at once, before it connects, if either is missing.

## The five local jobs {#local-jobs}

The first five run the Db2 CLI on the database host as the instance owner, through **IBM DB2 Database Host Credentials**. They are local-only: the agent must be on the same host as the Db2 instance, and they are unavailable on managed services such as Amazon RDS for Db2, which expose no host shell. See [Troubleshooting](troubleshooting.md#rds-for-db2).

- **The local-only rule is enforced.** Each job reads the target's `local` property, which the plug-in sets by comparing the Db2 host with the agent host. Unless the agent is on the Db2 host, the job fails at once with `ERROR: refusing to run: this job acts on the Db2 instance on the agent's own host…`, and nothing runs. A remotely monitored target's agent host may run a *different* Db2 instance, which the job would otherwise act on.
- **Start and Stop act on the whole instance.** Every database in the instance is affected, not just the target you selected, and Stop also forces off every connection. Both display names say so.
- **Parameters are validated** before any command is built. The application handle must be digits.
- **On Linux and UNIX, the instance owner must be able to read the agent's plug-in files.** The agent installs them readable only by the agent install owner and that owner's group. If the instance owner is not in that group, every job fails at once with `Can't open perl script ".../killagent.pl": Permission denied`. Add the instance owner to the agent install owner's group on the Db2 host, then submit the job again; no agent restart is needed:

  ```bash
  usermod -aG <agent install group> db2inst1      # for example oinstall
  ```

**The Analysis page's Kill button uses preferred credentials.** It submits the job without asking for any, so set the target's **IBM DB2 Database Host Credentials** first (`-set_name=DB2HostCreds` in the command above). Without them, the button reports *The kill job could not run. Check that preferred host credentials are set for this target.* Jobs created under **Enterprise → Job → Activity** use the same preferred credentials, or take explicit ones at submission. Every kill stays in **Enterprise → Job → Activity** as an audit record.

## Remote admin jobs {#remote-admin-jobs}

The three remote jobs do not need the agent on the database host. Each runs one Db2 command over `SYSPROC.ADMIN_CMD` on the target's own JDBC connection, as the user in **IBM DB2 Database Admin Credentials** — never the monitoring user — so they work on a remotely monitored target too.

| Job (display name) | Job type | Db2 command | Parameters | Authority (any one) |
| :--- | :--- | :--- | :--- | :--- |
| IBM Db2 - Force Application (remote) | `ip_db2_admin_force_application` | `FORCE APPLICATION (<handle>)` | Application Handle (digits) | SYSADM, SYSCTRL, SYSMAINT |
| IBM Db2 - RUNSTATS on a Table (remote) | `ip_db2_admin_runstats` | `RUNSTATS ON TABLE <schema>.<table> WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL` | Schema, Table (undelimited names) | DBADM, SQLADM, DATAACCESS, or CONTROL or LOAD on the table |
| IBM Db2 - Online Backup (remote) | `ip_db2_admin_backup` | `BACKUP DATABASE <db> ONLINE TO <directory> COMPRESS INCLUDE LOGS` | Backup Directory (absolute path on the database server) | SYSADM, SYSCTRL, SYSMAINT |

### The admin user

- **It also needs `EXECUTE` on `SYSPROC.ADMIN_CMD`.** SYSADM, SYSCTRL and SYSMAINT have it implicitly. For anyone else:

  ```sql
  GRANT EXECUTE ON PROCEDURE SYSPROC.ADMIN_CMD TO USER <admin user>;
  ```

- **A least-privilege admin user for all three** is a member of the instance's `SYSMAINT_GROUP` with `SQLADM`. That group can force applications and back up the database, and with `SQLADM` it can run RUNSTATS. Unlike SYSADM, it cannot change configuration or data. Set the group with `db2 update dbm cfg using SYSMAINT_GROUP <group>` and add the user to that operating-system group on the database server; `SQLADM` is granted in the database with `GRANT SQLADM ON DATABASE TO USER <admin user>`.
- **The force job checks the handle first, if it can.** `FORCE APPLICATION` accepts any number, so a mistyped handle would look like a success. When the admin user can read `MON_GET_CONNECTION` (`SQLADM`, or `EXECUTE` on that function), the job refuses a handle that is not connected. Without that privilege the force runs anyway, and its output says the handle was not checked.

### Before the first run

1. Set **IBM DB2 Database Admin Credentials** on the target: a named credential of type **IBM DB2 Database Credentials** holding the admin user (`-set_name=DB2AdminCreds` in the command above).
2. Set **IBM DB2 Plug-in Agent Owner Credentials** on the target: the agent install owner, who can read the plug-in's files (`-set_name=DB2AgentOwnerCreds`).

A job with either one missing fails at once with `Default preferred credentials are not set`, and never falls back to the monitoring user. Submitting the jobs needs **Full** privilege on the target, because the job runs as the admin user stored on it.

**Every value is checked before anything runs.** Schema and table must be plain Db2 names; the directory must be an absolute path with no spaces, quotes or commas; anything else is refused with a message naming the field. A refused value or a Db2 error fails the job, and the job output carries Db2's own message — for example `SQL2413N` when an online backup is attempted on a circular-logging database.

### Limitations

- **Backup:** online only, and it needs archive logging (`LOGARCHMETH1` not `OFF`). The backup directory is on the **database server**, not the agent host, and must exist and be writable by the instance owner.
- **No archive-log job.** `ADMIN_CMD` does not accept `ARCHIVE LOG`, so it cannot run remotely. The backup job's `INCLUDE LOGS` archives the active log as part of the backup; to archive the log on its own, run `db2 archive log for database <db>` on the database server.
- **TLS:** a target that connects with a custom client truststore is not supported by the remote jobs yet. TLS with the JVM's default trust store works.

## Purge Stale Plugin Cache {#purge-stale-cache}

**Do this once after every plug-in upgrade, or schedule it.** It is housekeeping, not a fix — skipping it wastes a small amount of disk and nothing else.

**Why it is needed.** Several metrics are deltas — they report the change since the previous collection (`Query_Analytics`, `Tablespace_Forecast`, and the rate metrics). To do that, the agent keeps a small cache file per target inside the *versioned* plug-in home. An upgrade creates a new home, so the previous version's cache files are stranded: a few KB per target, per version, left behind forever.

**Why it is not automatic.** Enterprise Manager provides no post-deployment or upgrade hook — there is no supported way for a plug-in to ask Enterprise Manager to run something when it is deployed. A scheduled job is the supported equivalent.

**Run it once, from the console:** **Enterprise → Job → Activity → Create Job**, choose **Purge Stale Plugin Cache**, and select any one Db2 target on the agent you want cleaned. The sweep covers that whole agent, so one target per agent is enough.

**Or schedule it and forget it.** The sweep is idempotent — it deletes only files that are already dead, and does nothing at all when there is nothing stale — so a weekly job costs nothing between upgrades and cleans up shortly after each one:

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

Add `-preview` to have Enterprise Manager describe the job it would create without creating it — the quickest way to check a property file, and it reports an unrecognised property name rather than silently ignoring it.

**Credentials — the one thing that catches people out.** The job needs host credentials for the account that **owns the agent installation** (commonly `oracle`), held in **IBM DB2 Plug-in Agent Owner Credentials** — not the Db2 instance owner the local jobs use. The plug-in's agent-side files are not world-readable, so a credential for any other OS user authenticates successfully and then cannot read the job's script. A user who can read them but does not own them (for example the Db2 instance owner, once it is in the agent group) runs the job but cannot delete the files, and the job fails with `Deleted 0 of N orphaned cache file(s); N could not be removed`. If the set is not configured, the job fails immediately with `Unable to get credentials for defaultHostCred`. To supply a credential explicitly instead:

```
cred.defaultHostCred.<target_name>:ip_db2_database=NAMED:<host_credential_name>
```

### What it will and will not delete

| Situation | Behaviour |
| :--- | :--- |
| Older plug-in homes from past upgrades | Cache files deleted. This is the case the job exists for. |
| The current plug-in home | **Never touched.** Guaranteed by construction — the job derives its prefix from its own home and sweeps only siblings. Your live delta metrics cannot be broken by running it. |
| Other plug-ins' directories | Never touched, for the same reason. |
| An unrecognised directory layout | Deletes nothing, rather than guessing. |
| A target you deleted | That target's cache file in the current home is left in place. It is inert and is removed with the plug-in home at the next upgrade or on undeploy. |
| Plug-in undeployed | Nothing to do; undeploy removes the plug-in homes wholesale. |

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

## Running a job

1. **Enterprise → Job → Activity → Create Job**.
2. Choose the job type from the table above.
3. Link the target to run it against, and give the job a meaningful name.
4. Enter the job's parameters: the **Application handle** for the kill and force jobs, the schema and table for RUNSTATS, the backup directory for the backup.
5. Confirm the credentials tab shows the right account — see [Credentials](#credentials) for which job needs which.
6. Submit, then track it from **Enterprise → Job → Activity** like any other Enterprise Manager job.

## Related

- [Prerequisites](prerequisites.md#preferred-credentials) — the credential sets, alongside the other prerequisites
- [Install and upgrade](install-and-upgrade.md#after-upgrade) — when to run Purge Stale Plugin Cache
- [Monitoring pages](monitoring-pages.md#analysis) — the Analysis page's Kill Blocking Application button
- [Troubleshooting](troubleshooting.md#jobs) — job failures by the message you see
