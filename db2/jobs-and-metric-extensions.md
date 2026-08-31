---
title: Jobs
nav_order: 11
---

# Jobs

The plug-in adds six Enterprise Manager job types for the `ip_db2_database_beta` target. Five are local-only administrative actions against the Db2 instance itself; the sixth is agent-side housekeeping you should run after every upgrade. There is no custom-query metric extension adapter in this release — if your site needs to collect its own SQL as a metric, that is not yet supported.

> **Prerequisites for this page**
> - The first five jobs need the agent **co-located on the same host as the Db2 instance** — see [Network and ports](prerequisites.md#network). They are not available for cloud-managed databases such as Amazon RDS for Db2.
> - All six jobs need [Preferred Credentials](prerequisites.md#preferred-credentials) set for the target, though the account differs by job — see the credentials note under each job below.

**Where to find it:** **Enterprise → Job → Activity → Create Job**; the Kill Application job also runs from the target's **Analysis** page.

**In this page:** Jobs shipped with the plug-in · The five local-only jobs · Purge Stale Plugin Cache · Running a job

## Jobs shipped with the plug-in

| Job (display name) | Job type | What it does | Privileges |
| :--- | :--- | :--- | :--- |
| Startup IBM DB2 | `sidb_startup_db2` | Starts the Db2 instance. | Host OS credentials (instance owner). |
| Shutdown IBM DB2 | `sidb_shutdown_db2` | Stops the Db2 instance. | Host OS credentials. |
| Quiesce IBM DB2 DB | `sidb_quiesce_dbinst` | Quiesces the database, blocking new connections. | Host OS credentials. |
| Unquiesce IBM DB2 DB | `sidb_unquiesce_dbinst` | Removes the quiesced state. | Host OS credentials. |
| Kill DB2 Application | `sidb_kill_agent` | Forces a specified application off the database (`db2 force application`). Also invoked by the **Kill Application** button on [Analysis](monitoring-pages.md#analysis). | Host OS credentials; requires an **Application ID** parameter. |
| Purge Stale Plugin Cache | `ip_db2_purge_stale_cache` | Deletes the metric-cache files a previous upgrade left behind in an older, no-longer-live plug-in home. Opens no database connection. | Host credentials for the **agent install owner** — see [below](#purge-stale-cache). |

## The five local-only jobs

The first five run the Db2 CLI on the database host, through the **host OS credentials** — the instance-owner OS account, `AgentOSCreds`. They are local-only by construction: the agent must be on the same host as the Db2 instance, and they are unavailable on managed services such as Amazon RDS for Db2, which expose no host shell. See [Troubleshooting](troubleshooting.md#rds-for-db2).

To run one: **Enterprise → Job → Activity → Create Job**, choose the job type, select the Db2 target, and (for **Kill DB2 Application**) supply the **Application ID**. Supply the host credentials when prompted, or set them in advance under [Preferred Credentials](prerequisites.md#preferred-credentials).

## Purge Stale Plugin Cache {#purge-stale-cache}

**Do this once after every plug-in upgrade, or schedule it.** It is housekeeping, not a fix — skipping it wastes a small amount of disk and nothing else.

**Why it is needed.** Several metrics are deltas — they report the change since the previous collection (`Top_Queries_*`, `Tablespace_Forecast`, and the rate metrics). To do that, the agent keeps a small cache file per target inside the *versioned* plug-in home. An upgrade creates a new home, so the previous version's cache files are stranded: a few KB per target, per version, left behind forever.

**Why it is not automatic.** Enterprise Manager provides no post-deployment or upgrade hook — there is no supported way for a plug-in to ask EM to run something when it is deployed. A scheduled job is the supported equivalent.

**Run it once, from the console:** **Enterprise → Job → Activity → Create Job**, choose **Purge Stale Plugin Cache**, and select any one Db2 target on the agent you want cleaned. The sweep covers that whole agent, so one target per agent is enough.

**Or schedule it and forget it.** The sweep is idempotent — it deletes only files that are already dead, and does nothing at all when there is nothing stale — so a weekly job costs nothing between upgrades and cleans up shortly after each one:

```bash
cat > purge_job.props <<'PROPS'
name=DB2_Purge_Stale_Cache
type=ip_db2_purge_stale_cache
target_list=<your_db2_target>:ip_db2_database_beta
schedule.frequency=WEEKLY
schedule.startTime=2026-09-01 03:00
schedule.days=1
PROPS

emcli create_job -input_file=property_file:purge_job.props
```

Add `-preview` to have EM describe the job it would create without creating it — the quickest way to check a property file, and it reports an unrecognised property name rather than silently ignoring it.

**Credentials — the one thing that catches people out.** The job needs host credentials for the account that **owns the agent installation** (commonly `oracle`), not the Db2 instance owner the other five jobs use. The plug-in's agent-side files are not world-readable, so a credential for any other OS user authenticates successfully and then cannot read the job's script. If no preferred host credential is set, the job fails immediately with `Unable to get credentials for defaultHostCred`. To supply one explicitly:

```
cred.defaultHostCred.<target_name>:ip_db2_database_beta=NAMED:<host_credential_name>
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

## Running a job

1. **Enterprise → Job → Activity → Create Job**.
2. Choose the job type from the table above.
3. Link the target to run it against, and give the job a meaningful name.
4. For **Kill DB2 Application**, enter the **Application ID** parameter.
5. Confirm the credentials tab shows the right account — see the table above for which job needs which.
6. Submit, then track it from **Enterprise → Job → Activity** like any other Enterprise Manager job.

## Related

- [Prerequisites](prerequisites.md#preferred-credentials) — setting Agent Host Credentials before a job needs them
- [Install and upgrade](install-and-upgrade.md#after-upgrade) — when to run Purge Stale Plugin Cache
- [Monitoring pages](monitoring-pages.md#analysis) — the Analysis page's Kill Application button
- [Troubleshooting](troubleshooting.md#rds-for-db2) — why these jobs are unavailable on Amazon RDS for Db2
