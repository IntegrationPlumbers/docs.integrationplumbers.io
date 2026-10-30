---
title: Upgrade notes
nav_order: 5.5
---

# Upgrade notes

Release notes for changes that need operator action beyond a routine deploy: an OMS restart, renamed metric groups whose history restarts, compliance rules that change scores, and licence settings. This page is for the Enterprise Manager administrator planning an upgrade. One section per release, **newest first**. The full list of what each release adds is on [What's new](whats-new.md).

**In this page:** [24.1.3.0.0 / 13.5.4.0.0 (from GA)](#update-24-1-3) · [GA 24.1.2.0.0 / 13.5.3.0.0 (from 24.1.1.0.0)](#update-24-1-2) · [Initial release 24.1.1.0.0 / 13.5.2.0.0](#ga)

## 24.1.3.0.0 / 13.5.4.0.0 (2026-10-30), from GA 24.1.2.0.0 {#update-24-1-3}

The first update of the GA release, installed in place over GA, 24.1.2.0.0 / 13.5.3.0.0. The database target metadata moves from 4.9 to 5.0, and the instance target from 1.3 to 1.4. Each note below says what changes, who it affects, and what to do. **Upgrading straight from the initial release, 24.1.1.0.0 / 13.5.2.0.0?** That works in place too: do everything in this section and in the [GA section](#update-24-1-2) below.

### Deploy to the OMS and every agent, then restart the OMS once {#restart-oms-24-1-3}

Metadata 5.0 appends one column, `never_backed_up`, to `DB_Backup`, a metric group the OMS has already registered. An OMS keeps each target type's column list in memory, so on an upgraded OMS the column stays empty, and a database that has never been backed up still raises no alert, until `emctl stop oms; emctl start oms`. Until then the Backup page's *Never* stays amber instead of red. A new OMS install needs no restart.

Deploy to the agents in the same window. The labels, credential set names and job names change once the OMS has the new version; the alert texts, the readable backup times, the Windows job fix, the purge job's output and the HADR standby log fix come from the agent, so they change as each agent gets it. An incident that is already open keeps the text it was raised with; the next one uses the new text. See [Upgrade](install-and-upgrade.md#upgrade).

### Associate the compliance standards with your targets again {#reassociate-standards}

The compliance framework, its three standards and the 29 rules are now authored `INTEGRATION_PLUMBERS`; before, they showed Author `SYSMAN`. Enterprise Manager identifies a standard by its name, author and version, so the upgrade removes the `SYSMAN` framework and standards and installs the new ones, and **their target associations are not carried over**. Until you associate them again, nothing is evaluated and the Db2 compliance results stay empty.

**What to do:** after the upgrade, associate the three standards with your IBM Db2 Database targets again, in **Enterprise → Compliance → Library** or with `emcli associate_cs_targets ... -author=INTEGRATION_PLUMBERS`, then check that the Library shows each standard with your targets. If you changed a rule parameter for a target, check it on the new association. Results come back after the evaluation the association starts. Leave HADR standbys without reads on standby out: they collect no configuration, so every standard scores 100 there without evaluating anything. See [Associate a standard with targets](compliance-standards.md#associate). A new install has nothing to re-associate.

### The two Top SQL groups are retired, and their stored rows deleted {#top-sql-retired}

`Top_Queries_Cpu_Time` and `Top_Queries_Execution_Count` stop collecting, and the upgrade **deletes the rows they stored**. A threshold, template entry or incident rule set on them does not carry over. Their two Conditions move to `Query_Analytics` as `CpuTime` and `Executions` (CPU time and executions of one statement per 15-minute interval), shipped Not Defined: set a value there if you alerted on the old groups. The SQL page is unchanged, because it already read `Query_Analytics` and `Statement_Text`. A statement that last ran before `Statement_Text` existed loses the text the old groups stored. See [Top SQL](metrics-reference.md#top-sql).

### Clear a table space threshold you set yourself {#tablespace-threshold}

The shipped Warning 80 / Critical 90 % table space alert moves from `Tablespace_Storage : tablespace_utilization` (used of allocated, now labelled *Tablespace Used of Allocated (%)*) to `Tablespace_Forecast : PctUsed` (used of maximum). The upgrade replaces the shipped 80 / 90 on `tablespace_utilization` with its new shipped default, none, so a target that still had the shipped values stops raising the old alert on its own.

A value you set yourself is kept, as every customised threshold is, so such a target can go on raising the old alert beside the new one. **What to do:** on those targets, open **Monitoring → Metric and Collection Settings**, find **Tablespace Storage**, and clear both values of *Tablespace Used of Allocated (%)*. Applying an updated monitoring template sets the new alert but does not clear the old one. See [Tablespace_Forecast](metrics-reference.md#tablespace-forecast).

### Check thresholds you set on three ratios {#ratio-thresholds}

`creation_to_assigning_ratio` (Agent Connection, both target types), `hashjoin_overflow_ratio` (Sort Heap) and `host_cpu_usage_per_sec` were labelled as percentages, though each is a plain ratio (0.25, not 25). They are unitless now. The values, and any threshold set on them, are unchanged. **If you set a threshold on one of them as a percentage**, 50 meant 50 % to the eye but is compared with the ratio, so it never fires: set 0.5 instead. None ships with a value.

### Re-import the incident rule set and the templates if you use them {#collateral-24-1-3}

The files that ship beside the plug-in changed with this release. Importing a new plug-in does not update them in your OMS:

- **Incident rule set.** `db2_incident_rules.sh import` now turns on the Warning rule by default, and both threshold rules cover the three thresholds the Production-critical template adds. Re-import with `./db2_incident_rules.sh import --overwrite --yes` to pick that up. **If you turned the Warning rule off, pass `--no-warnings` as well**: `import --overwrite --yes` and `enable` now turn it on without it. See [Incident rules](alerts-and-templates.md#incident-rules).
- **Monitoring templates.** All three carry the never-backed-up Critical and the new table space alert, and Production-critical raises its log-space alert on the first collection over 60 % instead of the third. Re-import with `emcli import_template -files=<file> -overwrite`, then apply it again. Applying sets every column the template names back to the template's value, so note any per-target change you made to those columns first. See [Monitoring templates](alerts-and-templates.md#monitoring-templates).

### Also check

- **A never-backed-up database now raises a Critical.** Expect it on new and development databases you do not back up, and clear `DB_Backup : never_backed_up` for those targets. See [DB_Backup](metrics-reference.md#db-backup).
- **Anything that matches the console names by text.** Credential sets, credential types, the two plug-in job types, the runbooks and several labels now say "IBM Db2" and "Db2" where they said "IBM DB2" and "DB2"; internal names (`DB2HostCreds`, `ip_db2_purge_stale_cache`, metric and column names) are unchanged. The plug-in is still listed as IBM DB2 Database under Plug-ins.
- **Run [the cache purge job](jobs-and-metric-extensions.md#purge-stale-cache) once per agent**, as after every upgrade. Its output now lists what it purged.
- **Known issue:** a successful online backup on a Windows agent was not lab-verified for this release. See [What's new](whats-new.md#known-issue-24-1-3).

## GA 24.1.2.0.0 / 13.5.3.0.0 (2026-10-23), from 24.1.1.0.0 {#update-24-1-2}

The general-availability release, installed in place over the initial release, 24.1.1.0.0 / 13.5.2.0.0. The database target metadata moves from 3.9 to 4.9, and the new IBM Db2 Instance target type arrives at 1.3. Each note below says what changes, who it affects, and what to do.

### Deploy to the OMS and every agent, then restart the OMS once {#restart-oms}

Several metric groups gain columns in this release: `Diag_Log_File_Monitoring.message_text`, `CollectorStatus.LastAttemptEpoch`, `License.license_severity`, and the per-second rate columns of `LogIO` and `Cache`. An OMS keeps each target type's column list in memory, so on an upgraded OMS these columns stay empty, and the licence-status alert does not fire, until `emctl stop oms; emctl start oms`. Until then the Transaction Log I/O chart on Performance and the cache rate chart on Memory & Sorts stay empty. A new OMS install needs no restart.

Deploy to the agents in the same window. An agent left on the previous version refuses the new backup job type (1.6) and runs nothing (`STDIN names DB_BACKUP_COMPRESS`). For the same reason, going back to the previous plug-in version is not a rollback for that job type: the OMS keeps job type 1.6. See [Upgrade from 24.1.1.0.0](install-and-upgrade.md#upgrade).

### Compliance scores drop on the first configuration collection {#compliance-scores}

New rules check settings that are Db2's own defaults: `LOCKTIMEOUT` -1 (`ip_db2_locktimeout_infinite`), and `CREATETAB`, `BINDADD` and `IMPLICIT_SCHEMA` granted to `PUBLIC` (`ip_db2_public_default_privileges`). Nearly every database associated with the standards therefore gains these violations. Any database not backed up in the last 7 days gains a Critical (`ip_db2_backup_too_old`). Enterprise Manager's out-of-box incident rule set opens an incident when a compliance score drops.

**What to do:** before the upgrade reaches production, decide per rule whether to fix the setting, change the rule's parameters for the target, or narrow the standard's target association. See [Compliance standards](compliance-standards.md).

### Seven lock and session groups are renamed, and their history restarts {#renamed-groups}

Each of these groups was keyed by a connection id, so every connection that ever appeared stayed a metric key in the repository for 24 months. They are replaced by groups whose keys cannot grow with connections:

| Retired group | Replaced by | Keyed by |
| :--- | :--- | :--- |
| `AgentStatistics` | `Application_Statistics` | Application name |
| `Sessions` | `Top_Sessions` | Rank by unit-of-work CPU (1 to 25) |
| `Open_Transactions` | `Oldest_Transactions` | Rank by age (1 to 20) |
| `Lock_Waits` | `Longest_Lock_Waits` | Rank by wait (1 to 25) |
| `Lock_Waits_By_Blkd_App` | `Lock_Waits_By_Blocked_App` | Application name |
| `Lock_Waits_By_Blkng_App` | `Lock_Waits_By_Blocking_App` | Application name |
| `Blocking_Chains` | `Blocking_Tree` | Position in the trees (1 to 50) |

On the upgrade Enterprise Manager **deletes the retired groups' stored data**. **Thresholds, templates and incident rules set on the old names do not move:** re-apply them on the new names. The shipped templates, the incident rule set and the shipped defaults (`Oldest_Transactions.uow_age_sec` Warning 1800 / Critical 7200 seconds) already use the new names, and the pages read the new groups. An alert on a ranked group is per position: `Oldest_Transactions` rank 1 is the oldest open transaction of the moment, and its message names the connection. See [Locking](metrics-reference.md#locking) and [Default thresholds](alerts-and-templates.md#default-thresholds).

### SQL statement history restarts under new keys {#statement-keys}

Statements are now keyed by digest (literal values replaced by `?`), and at most 200 new statement keys are added per target in any 24 hours. A window on the SQL page that reaches back before the upgrade shows a statement twice: the old literal-text rows and the new digest row. The old keys stop growing, and Enterprise Manager purges them 24 months after they last reported. The `Top_Queries_*` groups keep their exact-text key. To clear the old keys sooner, see [Statement metric keys](jobs-and-metric-extensions.md#statement-keys).

### Licence keys for 100 or more instances are now counted {#licence-count}

24.1.1.0.0 did not count keys of 100 instances or more. A target with such a key now needs the OMS Host, OMS Port and OMS credential that smaller keys already needed. Without them the **License** group reports a collection error naming the missing setting; the other groups keep collecting. An `Unlimited` key never contacts the OMS. See [The OMS settings](targets-and-properties.md#oms-settings).

The two 24.1.1.0.0 properties *OMS: skip certificate validation* and *OMS: allow cleartext HTTP fallback* are replaced by one **OMS API Communication** property (`STRICT` by default). A target that used either old property needs `SECURE` or `INSECURE`.

### Move the licence key into its credential set {#licence-credential}

Nothing breaks on the upgrade: the old *Plugin Licence Key* property is still read while the new credential is empty. While the key stays in the property, anyone who can view the target's properties can read it. To hide it, set the key in **IBM Db2 Plug-in Licence Monitoring Credentials** and then clear the property, target by target. See [Moving a key](targets-and-properties.md#moving-a-key).

An expired key now has a **14-day grace period**: the status reads `Grace Period`, collection continues and the alert is a Warning; then `Expired`, and collection stops. The status alert moves to the new `license_severity` column.

### TLS targets that run the remote admin jobs or Explain need the truststore credential set {#tls-truststore}

The remote admin jobs (RUNSTATS, Force Application, Online Backup) and Explain SQL Statement now connect with the target's client truststore. A target with **Use SSL/TLS?** = `yes` that relies on the agent JVM's default `cacerts`, with no truststore credential set, fails those jobs until the set points at that `cacerts`. Metric collection is not affected. See [TLS targets](jobs-and-metric-extensions.md#tls-targets).

### Adding instance targets doubles some alerts {#duplicate-alerts}

The new IBM Db2 Instance target collects the instance-scope groups (`Instance_Memory`, `Agent_Connection`, `FCM_Buffers`, `Latch_Waits`, `Memory_Sets`, `Diag_Log_File_Monitoring`), and database targets keep collecting them too, so one instance-level breach opens an incident on the instance and on each of its databases. Nothing changes until you add an instance target; then clear those thresholds on its database targets with a monitoring template. See [Duplicate alerts](targets-and-properties.md#duplicate-alerts).

### The console's page names changed {#page-names}

| 24.1.1.0.0 name | Now |
| :--- | :--- |
| Home | **Overview** |
| SQL Analytics | **SQL** |
| Analysis | **Locks** |
| Backup History | **Backup** |
| HADR | **High Availability** |

The transaction log, a section of Storage in 24.1.1.0.0, now has its own **Transaction Log** page, one of ten new database pages ([What's new](whats-new.md#update-24-1-2)). The target menu shows the new names after a full deploy or an OMS restart. The database target type is now spelled **IBM Db2 Database**, matching **IBM Db2 Instance**: existing targets keep their names, and the Add Target picker, the target menu and Preferred Credentials show the new spelling. The plug-in is still listed as IBM DB2 Database under Plug-ins. Chart and column labels are shorter (the unit moved to the chart's axis), so anything that matches a metric by its display label, rather than its internal name, needs the new text.

### Also check

- **The three monitoring templates replace the 24.1.1.0.0 threshold starter kit**, which reverted two shipped defaults on `tablespace_state` when applied. See [Monitoring templates](alerts-and-templates.md#monitoring-templates).
- **The plug-in no longer writes inside its agent plug-in home.** Target caches and the plug-in log move to `<agentStateDir>/ip_plugin/xdb2/`. Run [the cache purge job](jobs-and-metric-extensions.md#purge-stale-cache) (**Purge Orphaned IBM Db2 Plug-in Cache Files**) once per agent to remove the 24.1.1.0.0 copies.
- **The DRDA encryption property is relabelled** *DRDA Credential Encryption AES-256*: it encrypts the user ID and password, not the data. The setting and its values are unchanged.
- **AIX, Solaris and HP-UX agents are declared unsupported.** The plug-in was already certified for Linux x86-64 and Windows x86-64 agents only.
- **Monitoring templates saved from the console before this release** keep their old alert message ids, which still resolve to the English text.

## Initial release 24.1.1.0.0 / 13.5.2.0.0 (2026-10-12) {#ga}

The initial release of `ip.em.xdb2`. It was a fresh install: there was no earlier release to upgrade from, and moving from the Open Beta is a clean install side by side ([Moving from the beta to GA](beta-pre-release.md)). What changed for beta users (renamed job types, the retired `DataFiles` group, new default alerts and intervals) is on [What's new](whats-new.md#ga).

## Related

- [Install and upgrade](install-and-upgrade.md#upgrade): the upgrade steps
- [What's new](whats-new.md#update-24-1-3): everything in this release
- [Changelog](changelog.md): each release in brief
