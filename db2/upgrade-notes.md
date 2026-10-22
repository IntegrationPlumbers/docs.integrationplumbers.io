---
title: Upgrade notes
nav_order: 5.5
---

# Upgrade notes

Release notes for changes that need operator action beyond a routine deploy: an OMS restart, renamed metric groups whose history restarts, compliance rules that change scores, and licence settings. This page is for the Enterprise Manager administrator planning an upgrade. One section per release, **newest first**. The full list of what each release adds is on [What's new](whats-new.md).

**In this page:** 24.1.2.0.0 / 13.5.3.0.0 (from GA) · GA 24.1.1.0.0 / 13.5.2.0.0

## 24.1.2.0.0 / 13.5.3.0.0 (2026-10-23), from GA {#update-24-1-2}

The first in-place update of GA 24.1.1.0.0 / 13.5.2.0.0. The database target metadata moves from 3.9 to 4.9, and the new IBM Db2 Instance target type arrives at 1.3. Each note below says what changes, who it affects, and what to do.

### Deploy to the OMS and every agent, then restart the OMS once {#restart-oms}

Several metric groups gain columns in this release: `Diag_Log_File_Monitoring.message_text`, `CollectorStatus.LastAttemptEpoch`, `License.license_severity`, and the per-second rate columns of `LogIO` and `Cache`. An OMS keeps each target type's column list in memory, so on an upgraded OMS these columns stay empty, and the licence-status alert does not fire, until `emctl stop oms; emctl start oms`. Until then the Transaction Log I/O chart on Performance and the cache rate chart on Memory & Sorts stay empty. A new OMS install needs no restart.

Deploy to the agents in the same window. An agent left on the previous version refuses the new backup job type (1.6) and runs nothing (`STDIN names DB_BACKUP_COMPRESS`). For the same reason, going back to the previous plug-in version is not a rollback for that job type: the OMS keeps job type 1.6. See [Upgrade from GA](install-and-upgrade.md#upgrade).

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

GA did not count keys of 100 instances or more. A target with such a key now needs the OMS Host, OMS Port and OMS credential that smaller keys already needed. Without them the **License** group reports a collection error naming the missing setting; the other groups keep collecting. An `Unlimited` key never contacts the OMS. See [The OMS settings](targets-and-properties.md#oms-settings).

The two GA properties *OMS: skip certificate validation* and *OMS: allow cleartext HTTP fallback* are replaced by one **OMS API Communication** property (`STRICT` by default). A target that used either old property needs `SECURE` or `INSECURE`.

### Move the licence key into its credential set {#licence-credential}

Nothing breaks on the upgrade: the old *Plugin Licence Key* property is still read while the new credential is empty. While the key stays in the property, anyone who can view the target's properties can read it. To hide it, set the key in **IBM DB2 Plug-in Licence Monitoring Credentials** and then clear the property, target by target. See [Moving a key](targets-and-properties.md#moving-a-key).

An expired key now has a **14-day grace period**: the status reads `Grace Period`, collection continues and the alert is a Warning; then `Expired`, and collection stops. The status alert moves to the new `license_severity` column.

### TLS targets that run the remote admin jobs or Explain need the truststore credential set {#tls-truststore}

The remote admin jobs (RUNSTATS, Force Application, Online Backup) and Explain SQL Statement now connect with the target's client truststore. A target with **Use SSL/TLS?** = `yes` that relies on the agent JVM's default `cacerts`, with no truststore credential set, fails those jobs until the set points at that `cacerts`. Metric collection is not affected. See [TLS targets](jobs-and-metric-extensions.md#tls-targets).

### Adding instance targets doubles some alerts {#duplicate-alerts}

The new IBM Db2 Instance target collects the instance-scope groups (`Instance_Memory`, `Agent_Connection`, `FCM_Buffers`, `Latch_Waits`, `Memory_Sets`, `Diag_Log_File_Monitoring`), and database targets keep collecting them too, so one instance-level breach opens an incident on the instance and on each of its databases. Nothing changes until you add an instance target; then clear those thresholds on its database targets with a monitoring template. See [Duplicate alerts](targets-and-properties.md#duplicate-alerts).

### The console's page names changed {#page-names}

| GA name | Now |
| :--- | :--- |
| Home | **Overview** |
| SQL Analytics | **SQL** |
| Analysis | **Locks** |
| Transaction Log & Recovery | **Transaction Log** |
| Backup History | **Backup** |
| HADR | **High Availability** |

The target menu shows the new names after a full deploy or an OMS restart. The database target type is now spelled **IBM Db2 Database**, matching **IBM Db2 Instance**: existing targets keep their names, and the Add Target picker, the target menu and Preferred Credentials show the new spelling. The plug-in is still listed as IBM DB2 Database under Plug-ins. Chart and column labels are shorter (the unit moved to the chart's axis), so anything that matches a metric by its display label, rather than its internal name, needs the new text.

### Also check

- **The three monitoring templates replace the GA threshold starter kit**, which reverted two shipped defaults on `tablespace_state` when applied. See [Monitoring templates](alerts-and-templates.md#monitoring-templates).
- **The plug-in no longer writes inside its agent plug-in home.** Target caches and the plug-in log move to `<agentStateDir>/ip_plugin/xdb2/`. Run [Purge Stale Plugin Cache](jobs-and-metric-extensions.md#purge-stale-cache) once per agent to remove the GA copies.
- **The DRDA encryption property is relabelled** *DRDA Credential Encryption AES-256*: it encrypts the user ID and password, not the data. The setting and its values are unchanged.
- **AIX, Solaris and HP-UX agents are declared unsupported.** The plug-in was already certified for Linux x86-64 and Windows x86-64 agents only.
- **Monitoring templates saved from the console before this release** keep their old alert message ids, which still resolve to the English text.

## GA 24.1.1.0.0 / 13.5.2.0.0 (2026-10-12) {#ga}

The first general-availability release. It was a fresh install: there was no earlier GA release to upgrade from, and moving from the Open Beta is a clean install side by side ([Moving from the beta to GA](beta-pre-release.md)). What changed for beta users (renamed job types, the retired `DataFiles` group, new default alerts and intervals) is on [What's new](whats-new.md#ga).

## Related

- [Install and upgrade](install-and-upgrade.md#upgrade): the upgrade steps
- [What's new](whats-new.md#update-24-1-2): everything in this release
- [Changelog](changelog.md): each release in brief
