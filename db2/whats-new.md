---
title: What's new
nav_order: 1
---

# Release notes

The changes in each release of the IBM Db2 plug-in, newest first, for anyone deciding whether to upgrade or checking what a release changed. Each release ships as two builds with the same features: one for Enterprise Manager 24ai and one for Enterprise Manager 13.5. Install the build that matches your Enterprise Manager.

**In this page:** [24.1.2.0.0 / 13.5.3.0.0 (2026-10-22)](#update-24-1-2) · [General availability: 24.1.1.0.0 / 13.5.2.0.0 (2026-10-12)](#ga) · [Feedback](#feedback)

## 24.1.2.0.0 (Enterprise Manager 24ai) / 13.5.3.0.0 (Enterprise Manager 13.5), 2026-10-22 {#update-24-1-2}

The first update after GA, installed over 24.1.1.0.0 / 13.5.2.0.0 in place ([Upgrade from GA](install-and-upgrade.md#upgrade)). The database target metadata moves from 3.9 to 4.9, and a second target type, IBM Db2 Instance, arrives at 1.3. [Upgrade notes](upgrade-notes.md#update-24-1-2) lists every change that needs operator action.

#### Functionality Added or Changed

- **A redesigned console.** Every page opens with the question it answers, a toolbar, a row of KPI tiles and then its regions, with a left navigation grouped as Workload, Storage and Logs, and Protection ([Monitoring pages](monitoring-pages.md)). Several pages are renamed: Home is **Overview**, SQL Analytics is **SQL**, Analysis is **Locks**, Transaction Log & Recovery is **Transaction Log**, Backup History is **Backup**, and HADR is **High Availability**.
- **Ten new database pages:** Sessions, Waits, Members, Tables, Indexes, Transaction Log, Memory & Sorts, Configuration, Monitoring Readiness and License Info ([IBM Db2 Database pages](monitoring-pages.md#51-ibm-db2-database-pages)). The Overview gains a **Database** card, a **Monitoring and License** card and seven Key Indicators tiles.
- **Monitoring Readiness** checks the connection, licence, monitor authority, metric collection, monitor switches, deadlock capture, HADR and the diagnostic log, live on the agent, and prints the statement that fixes each, with a Copy button ([Monitoring Readiness](monitoring-pages.md#monitoring-readiness)). The Overview shows an hourly count of the same checks ([readiness_summary](metrics-reference.md#readiness-summary)). A [troubleshooting guide for AI assistants](https://docs.integrationplumbers.io/db2/ai/troubleshooting.md), published with this guide as a Markdown file, covers the same checks in a form you can load into your own assistant together with the page's results.
- **Statement Detail** charts a statement's executions and CPU and activity time over the window, copies its text, and runs **Explain Plan**, which shows the access plan of the statement's cached section without running it ([Explain SQL Statement](jobs-and-metric-extensions.md#explain)). It opens from SQL, Sessions and Recent Deadlocks on Locks.
- **Auto-refresh** on Locks and Sessions: Off, 30 seconds, 1 minute or 5 minutes. Each live read runs a collection on the agent, and the live reads pause while the browser tab is in the background ([Time windows, auto-refresh and live reads](monitoring-pages.md#53-time-windows-auto-refresh-and-live-reads)).
- **Back Up Database** on the Backup page: an online backup now, once later or daily ([Backup](monitoring-pages.md#backup)). It submits the remote Online Backup job, now job type 1.6 with **Compress the Backup Image** and **Include Logs** options. A partitioned (DPF) database is refused, by the dialog and by the job itself ([Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs)).
- **Sessions, Blocking Chains and Recent Deadlocks.** Sessions lists the 25 sessions using the most CPU in their current unit of work, with **Kill** on each row. Locks shows who waits on whom down to the root blocker, with **Kill** on the root blocker's row, and, once a DBA has set up deadlock capture, the past day's deadlocks with every participant ([Locks](monitoring-pages.md#locks)).
- **IBM Db2 Instance target type** with its own six pages ([Instance targets](targets-and-properties.md#instance-targets)): availability, instance memory against its limit, memory sets, active databases, agents, FCM buffers, latch waits, the instance's db2diag.log and its own daily configuration snapshot. Start and Stop IBM Db2 Instance run from it. Instance targets need a licence key but do not count against its instance limit.
- **Automatic discovery** of local databases on Linux and Windows agent hosts, with no setup and no password ([Target discovery](discovery.md)).
- **Partitioned (DPF) databases are supported**: every query reads all active members and reports the database as a whole, and `Member_Status` alerts when a member is down ([Partitioned (DPF) databases](metrics-reference.md#dpf)). pureScale member and CF health is implemented, not lab-certified ([pureScale](metrics-reference.md#purescale)).
- **New monitoring:** log archiving (`Log_Archive`), instance memory and memory sets, where request time waits (`Wait_Time`), latches, buffer-pool I/O time, FCM, WLM workloads and service classes (no WLM licence needed), index activity and unused indexes, blocking chains, opt-in deadlock capture, sessions and the oldest open transactions, and per-second log and cache rates ([Metrics reference](metrics-reference.md)). New default alerts ship on several of them ([Default thresholds](alerts-and-templates.md#default-thresholds)).
- **Compliance:** twelve new rules on security settings, privileges granted to `PUBLIC`, DBADM and SECADM holders, trusted contexts and backup age, for 29 rules in three standards ([Compliance standards](compliance-standards.md)).
- **Archive IBM Db2 Active Log**, a new local job, which an administrator can attach as a corrective action to the log-space alert; nothing ships attached ([Corrective action](jobs-and-metric-extensions.md#corrective-action)).
- **Three monitoring templates (Starter, Standard and Production-critical), an incident rule set, and configuration comparison and drift definitions** ship beside the plug-in ([Monitoring templates](alerts-and-templates.md#monitoring-templates), [Incident rules](alerts-and-templates.md#incident-rules)). The templates replace the GA threshold starter kit.
- **Kerberos authentication** ([Kerberos](prerequisites.md#kerberos)), an optional agent-load throttle ([Pausing collection](prerequisites.md#collection-throttle)), optional batch collection ([Batch collection](prerequisites.md#batch-collection)), and IPv6 hosts ([IPv6 hosts](targets-and-properties.md#ipv6)).
- **The licence key is a credential**, hidden from target properties, with a 14-day grace period after expiry, and one **OMS API Communication** setting for the licence count ([Licensing](targets-and-properties.md#licensing)).
- **Statements are keyed by digest**, so literal values no longer create new repository keys, and at most 200 new statement keys are added per target a day ([Statement metric keys](jobs-and-metric-extensions.md#statement-keys)).
- **The plug-in no longer writes inside its agent plug-in home.** Target caches and the plug-in log go to `<agentStateDir>/ip_plugin/xdb2/`, so CollectorStatus history survives an agent plug-in upgrade ([Files the plug-in keeps on each agent](jobs-and-metric-extensions.md#agent-files)).
- **Release downloads are signed**: each OPAR comes with a `SHA256SUMS` file and a detached cosign signature for each file ([Verify the download](install-and-upgrade.md#verify)).
- **The target type is named IBM Db2 Database**, matching IBM Db2 Instance, and chart legends are shorter, with the unit on the chart's axis. The console theme (1.1.0) has higher-contrast colours that meet WCAG 2.2 AA, and Days to Full on Storage is coloured amber under 30 days and red under 7.
- **Text for translation.** Job types, every console page and the target metadata's labels, descriptions and alert messages take their text from an English resource bundle. Nothing looks different in English; every alert message now has its own message id.

#### Bugs Fixed

- The oldest open transaction no longer reads *0 s*: units of work younger than 5 seconds and the plug-in's own connections are left out.
- Numeric table columns (wait times and application handles on Locks) sort as numbers.
- Wait_Time and Query_Analytics no longer report one inflated interval when a DPF partition stops or comes back: a change in the partitions read starts a new baseline ([Wait_Time](metrics-reference.md#wait-time)).
- Top Statements retries the SQL text after a failed lookup (the [GA known issue](#known-issue)).
- Performance shows one row per buffer pool and per database on every window, and cache lookup counts are per collection interval, so an idle cache no longer reads as a perfect one.
- Diagnostic-log alerts carry the matched message, and CollectorStatus no longer fills the repository's string history.
- The remote admin jobs and Explain run over TLS with the target's client truststore, and a target can be reached over IPv6.
- Security: the Host, Port and Database Name properties, and remote admin job parameters, are checked before use, so a crafted value cannot add driver settings to the connection.
- Tables fit their regions: headers wrap, and a table wider than its region scrolls inside its frame.
- Table_Maintenance checks user schemas whose names begin with `SYS`, such as PeopleSoft's `SYSADM`.
- The licence instance count is sturdier: it counts only this plug-in's target type, each target once; an OMS answer that is not a target list is an error, never a count of 0; and a count under 7 days old stands in during a short OMS outage.

#### Upgrade notes

Full detail, with what to do for each, is on [Upgrade notes](upgrade-notes.md#update-24-1-2).

- Deploy to the OMS and to every agent, then restart the OMS once: appended columns stay empty, and the licence-status alert does not fire, until it restarts ([details](upgrade-notes.md#restart-oms)).
- Seven lock and session metric groups are renamed and their stored history restarts; re-apply thresholds set on the old names ([details](upgrade-notes.md#renamed-groups)).
- Compliance scores drop on the first configuration collection, because the new rules check Db2's own defaults ([details](upgrade-notes.md#compliance-scores)).
- SQL statement history restarts under digest keys ([details](upgrade-notes.md#statement-keys)).
- A licence key for 100 or more instances now needs the OMS settings ([details](upgrade-notes.md#licence-count)); move each key into its credential set when ready ([details](upgrade-notes.md#licence-credential)).
- A TLS target that runs the remote admin jobs or Explain needs its client truststore credential set ([details](upgrade-notes.md#tls-truststore)).
- Adding instance targets doubles the instance-level alerts until you clear them on the database targets ([details](upgrade-notes.md#duplicate-alerts)).

#### Known limitations and boundaries

- **Amazon RDS for Db2 is not certified.** Monitoring over JDBC has been verified on Db2 12.1.5 on RDS; the formal certified status waits for sign-off. The local jobs and diagnostic-log monitoring are unavailable, because the agent cannot run on the database host. Of the remote admin jobs, RUNSTATS works (over TLS too), and Force Application and Online Backup fail with `SQL1092N`, because no RDS user holds SYSADM, SYSCTRL or SYSMAINT ([Troubleshooting](troubleshooting.md#rds-for-db2)).
- **Db2U and IBM Db2 SaaS are not certified** and have not been tested; the connection settings are written from IBM's documentation ([Db2U and IBM Db2 SaaS](targets-and-properties.md#db2u-saas)).
- **pureScale is implemented, not lab-certified:** member, CF and group buffer pool health only; every other group stays off on pureScale.
- **On DPF**, the HADR groups and diagnostic-log monitoring are not collected, `DB_History` lists the catalog partition's recovery history only, and Online Backup is refused ([Partitioned (DPF) databases](metrics-reference.md#dpf)).
- **Deep HADR monitoring requires a standby pair**, and a standby without reads on standby reports availability only ([Monitoring a standby](hadr-monitoring.md#monitoring-a-standby)).
- **Local-only features.** Diagnostic-log monitoring, the six local jobs and the Kill buttons need the agent on the Db2 host ([Network and ports](prerequisites.md#network)).
- **Adding an IBM Db2 Instance target duplicates the instance-level alerts** on its database targets until you clear them there ([Duplicate alerts](targets-and-properties.md#duplicate-alerts)).
- **The latch figures on Waits are for the whole instance**, every database on it, not this database alone.
- **Tables and Indexes show what is collected:** table size covers only the tables that need statistics or a reorg (at most 100), index size only the indexes scanned in the last interval and the unused ones, "Invalid objects" counts packages and objects, not indexes, and missing indexes are not collected ([Tables](monitoring-pages.md#tables), [Indexes](monitoring-pages.md#indexes)).
- **Last week and Last month read hourly averages**, so peaks look lower, and Statement Detail calls the window figures a relative size, not a total.
- **Back Up Database scheduling:** Once and Daily are verified on Enterprise Manager 24ai, and Once on 13.5. A console that cannot build the schedule says so and submits nothing.
- **Kerberos** is verified on a Linux agent with a principal and password; Windows agents, keytab and ticket-cache modes were not verified. **Batch collection** is not yet verified on Windows agents.
- **Importing the monitoring templates on Enterprise Manager 13.5** has not been tested.
- **Discovery on Windows** reads the Db2 command line's English output, so a host whose Db2 messages are in another language finds nothing ([Target discovery](discovery.md)).
- **Federation and BLU (column-organized) databases** are monitored with the standard metric set, but nothing specific to them is collected.
- **Not supported:** Db2 for z/OS, Db2 11.1 and below, and AIX, Solaris and HP-UX agents ([Supported versions](prerequisites.md#supported-versions)).
- **Not covered in this release:** BLU and federation metrics, pureScale certification, AI Query Optimizer monitoring and Q Replication.

## General availability: 24.1.1.0.0 (Enterprise Manager 24ai) / 13.5.2.0.0 (Enterprise Manager 13.5), 2026-10-12 {#ga}

*24.1.2.0.0 / 13.5.3.0.0, above, upgrades this release in place. Page names in this section are the GA names (Home, Analysis, SQL Analytics, Backup History and HADR).*

This is the first general-availability (GA) release of the IBM Db2 plug-in, `ip.em.xdb2`, released on 2026-10-12. It ships as two builds with the same features: **24.1.1.0.0** for Enterprise Manager 24ai and **13.5.2.0.0** for Enterprise Manager 13.5. The two lines are versioned independently. Both builds have been verified on a live Enterprise Manager, including deployment and every console page.



### Read this first {#read-this-first}

- **This is the first GA release**, so there is no earlier GA release to upgrade from. Install it fresh: see [Getting started](getting-started.md). The first GA update after it is the first release that upgrades in place.
- **Moving from the Open Beta is a clean install, not an upgrade.** GA is a different plug-in from the Open Beta:

  | | Open Beta | GA |
  | :--- | :--- | :--- |
  | Plug-in ID | `ip.em.xdbb` | `ip.em.xdb2` |
  | Target type | `ip_db2_database_beta` | `ip_db2_database` |
  | Display name | IBM DB2 Database (Beta) | IBM DB2 Database |

  Nothing from a beta install carries over. Add the targets again under GA, and set thresholds, templates and credentials on them again. The two plug-ins can run side by side on one OMS and agent while you move over. A beta licence key does not unlock GA. When the move is done, undeploy the beta. The steps are on [Moving from the beta to GA](beta-pre-release.md).
- **What changes for anyone coming from the beta:**
  - The administrative job types are renamed. See [Breaking changes](#breaking-changes).
  - Availability reads differently. An HADR standby is up, not down. A database on an unsupported Db2 version or topology still reports availability, and says what it cannot collect.
  - Alerts and collection intervals have new defaults. See [Changed defaults](#changed-defaults).
- **Support levels.** Db2 12.1 is certified at the Comprehensive level, and Db2 11.5 at the Basic level. Every metric collects on both. The level is the certification label in Enterprise Manager's plug-in catalog. Amazon RDS for Db2 is not certified: see [Troubleshooting](troubleshooting.md#rds-for-db2).

### Known issue {#known-issue}

**After one failed text lookup, Top Statements keeps showing numbers without SQL text** on the SQL Analytics page, until you change the time window or the ranking. Refreshing the page does not retry the lookup. The ranking and the numbers stay correct. This is fixed in the first update after GA.

### Breaking changes {#breaking-changes}

**Every administrative job type is renamed.** Job type names are global across the OMS. The old names sat in the namespace of Oracle's own Db2 plug-in, which this plug-in is designed to run alongside.

| Before | GA job type |
| :--- | :--- |
| `sidb_startup_db2` | `ip_db2_start_instance` |
| `sidb_shutdown_db2` | `ip_db2_stop_instance` |
| `sidb_quiesce_dbinst` | `ip_db2_quiesce_database` |
| `sidb_unquiesce_dbinst` | `ip_db2_unquiesce_database` |
| `sidb_kill_agent` | `ip_db2_kill_application` |

Job history, saved jobs and library entries recorded under the old names do not carry over. The beta's names were `sidbb_*`, and moving from the beta is a clean install anyway. See [Jobs](jobs-and-metric-extensions.md).

**DataFiles is retired and replaced by Table_Overflow** ("Table Overflow and Reorganization"). DataFiles keyed each row on a cumulative reorganization counter, so every reorg gave a table a new row identity. Table_Overflow keys on schema and table and carries the same counters. It keeps one row per table, summed over data partitions, leaves out temporary tables, and uploads the 100 tables with the most overflow accesses. A threshold or monitoring template set on `DataFiles.overflow_accesses` does not move to the new group: set it again on `Table_Overflow.overflow_accesses`.

### Statement text and your data {#statement-text-privacy}

The SQL Analytics page now shows the SQL text of each statement. That text is **stored in the Enterprise Manager repository, and it can contain data**:

- Db2 records SQL as it was submitted. A statement with literal values (names, IDs, amounts) carries those values in its text, unless the application uses parameter markers or the database's statement concentrator replaces literals.
- The **SQL Statement Text** metric group (`Statement_Text`) keeps that text with the repository's string metric history. Enterprise Manager retains that history for 12 months by default.
- The Top Queries groups (by CPU time and by execution count) also store statement text, and their alert messages include it.

**To stop collecting it**, disable **SQL Statement Text** for the target under **Monitoring → Metric and Collection Settings → Other Collected Items**, or in a monitoring template. With EM CLI:

```
emcli modify_collection_schedule -targetType=ip_db2_database -targetNames=<target> \
      -collectionName=Statement_Text -collectionStatus=Disabled
```

Top Statements then shows its numbers without the text.

### What's new for monitoring {#monitoring}

- **SQL text for any window.** Top Statements follows the SQL Analytics page's time window, from the last hour to the last month, and shows each statement's SQL text. The new **SQL Statement Text** group stores each statement's text at most once a day. It reads what the analytics collection already fetched, so it adds no load on the database. Text is flattened to one line and cut at 2,000 characters.
- **Storage-path headroom.** A new `Storage_Paths` group, collected every 30 minutes, reports each automatic-storage path's file system. A shipped alert warns at 85% used and goes critical at 95%.
- **A forecast for unlimited table spaces.** `Tablespace_Forecast` now forecasts auto-resize table spaces that have no maximum size, which is the Db2 default. The ceiling is the free space on their storage group's file systems. Before, they read `9999` (no forecast). A new `CapacitySource` column says which limit applies.
- **Table maintenance.** A new `Table_Maintenance` group (every 6 hours) lists tables whose statistics are stale or that need a reorg. A new `Invalid_Objects` group (hourly) counts packages that need a rebind and other invalid objects.
- **Open and idle-in-transaction units of work.** A new `Open_Transactions` group (every 5 minutes) lists the oldest open units of work. That includes idle-in-transaction sessions, which hold locks and pin the active log. `Log_Storage` now names the connection holding the oldest transaction, and for how long.
- **Lock-list use.** `DB_Monitoring` adds the lock-list size and how much of it is in use. An alert at 70% / 85% warns ahead of the lock escalations a full lock list causes.
- **Running utilities and a wider recovery history.** New `Utilities` and `Rebalance_Status` groups show the utilities running now, with a long-running alert, and the table spaces being rebalanced. `DB_History` adds reorg and rollforward entries, and a failed reorg or rollforward raises the same alert as a failed backup.
- **Monitor-switch check.** A new `Monitor_Metrics` group warns when a `MON_*_METRICS` switch is `NONE`. At `NONE`, Db2 returns zeros rather than real metrics, so dashboards look healthy while measuring nothing. The alert message gives the online fix.
- **Curated db2diag.log patterns.** Diagnostic-log monitoring ships a default pattern set: administration-notification errors, log full, table space full, HADR errors, critical records, traps and panics. Your own pattern files go in the agent state directory, which upgrades do not touch. A record that names another database is reported only by that database's target.
- **An HADR standby is monitored as a standby.** A standby reads Up, raises no collection errors for the groups it cannot serve, and can be added as a target in its own right. See [HADR monitoring](hadr-monitoring.md#monitoring-a-standby).
- **Follow the HADR primary through a takeover.** Five optional target properties turn on the driver's client reroute. A target given the other side of its pair as an alternate reads the new primary after a takeover, and the original after a failback. See [HADR monitoring](hadr-monitoring.md#client-reroute).
- **Unsupported versions and topologies fail open, and say so.** Availability collects on any Db2 version. Every other group is limited to 11.5 and 12.1. Partitioned (DPF) and pureScale databases are detected and gated off. CollectorStatus names the reason for each group it gates off.
- **Topology associations.** Each database is linked to the host target it runs on. A target with HADR alternates set is linked to the standby targets they name.
- **TLS hardening.** A new optional **TLS Hostname Validation** property (`BASIC`, the default, or `OFF`). The security mechanism is now explicit. A TLS failure names its cause instead of reading as the database being down. See [Optional transport security](prerequisites.md#tls).
- **Collection telemetry.** CollectorStatus adds how long each group's last collection took and how many attempts in a row have failed.

### What's new in the console {#console}

- **Seven pages:** Home, Analysis, Performance, Storage, Backup History, SQL Analytics and HADR. See [Monitoring pages](monitoring-pages.md).
- **Home health overview.** One row per area: availability, storage, transaction log, backup and recovery, HADR, locks, performance, SQL workload, licence, and diagnostics. Each row shows Enterprise Manager's own current verdict, the number of open alerts, the worst alert's message, and a link to the page behind it. The verdicts come from Enterprise Manager's alerts, so the overview cannot disagree with the Incidents list after you tune a threshold.
- **The pages link up.** Home shows **Related Targets**: the Db2 server, the HADR partner, the monitoring agent and its host. Analysis shows **Job Activity** and **Incidents and Problems**, and HADR shows its incidents too.
- **Each alerting metric is on the page its alert sends you to.** Backup History opens with a Last Backup section, and Storage has a Transaction Log section.
- **A time window on Storage, Backup History and HADR.** Each page gains a **Trend** section (Past hour, Past day, Past week, Past month). The trend reads stored data, so it adds no load on the database. One set of window labels is used across every page.
- **The console asks the agent for less.** Real-time charts on Home and Performance refresh once a minute. A real-time chart now starts empty and fills in as samples arrive; for history, pick **Past hour** or longer on Performance.
- **Theme and accessibility.** Status colours come from the shared Integration Plumbers theme, and a status is always a word as well as a colour. Screen readers announce every section, chart and table. Long text cells stay inside their column, with the full text in the tooltip.

### What's new for administration {#administration}

- **Three remote admin jobs:** Force Application, RUNSTATS on a Table, and Online Backup. They work on any target, including a remotely monitored one. Each runs one Db2 command over `SYSPROC.ADMIN_CMD` on the target's JDBC connection. They run as a separate admin user, held in the new **IBM DB2 Database Admin Credentials** preferred credential set, and never as the monitoring user. Every parameter is validated before anything runs. See [Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs).
- **Kill Blocking Application.** The Analysis page's kill action now sits on the *Blocking* table, so it forces the lock holder rather than the waiter. It asks for an explicit Yes naming the application, then reports the result.
- **The five local admin jobs enforce "local only".** Each refuses to run unless the agent is on the target's Db2 host, and none passes job parameters to a shell. Start and Stop are labelled as instance-wide.
- **Preferred host credentials.** The local jobs use a new **IBM DB2 Database Host Credentials** set. Set it per target before you use the Kill button.
- **Six runbooks (Enterprise Manager 24ai).** Runbooks for the most common Db2 alerts install with the plug-in, and Enterprise Manager recommends each on the matching incident. See [Alerts and thresholds](alerts-and-templates.md#runbooks).
- **A diagnostics job.** *Collect IBM DB2 Plug-in Diagnostics* writes one archive of the plug-in's logs and environment for support, with every credential redacted.
- **17 compliance rules.** Five rules join the three standards: the instance offers TLS; on Windows, Db2 extended security is not turned off; audit records are written asynchronously; SYSADM belongs to a named group; and the server runs the latest modification pack of its release. See [Compliance standards](compliance-standards.md).

### Changed defaults {#changed-defaults}

**New default alerts.** Several conditions that used to ship with no value now alert out of the box: table space fault states; HADR log gap, replay gap, replay lag and standby state; lock escalations; IBM licence feature use; database and instance status; and secondary logs in use. `sec_logs_allocated` now alerts on "more than 0"; before, it fired on the healthy value. The full list is on [Alerts and thresholds](alerts-and-templates.md#default-thresholds).

**Shorter collection intervals** for the metrics whose alerts could lag:

| Metric group | Was | Now |
| :--- | :--- | :--- |
| `Lock_Waits` and its three roll-ups | 30 min | 5 min |
| `HADR_Status` | 45 min | 15 min |
| `DB_Backup` | 2 h | 30 min |

All of them read light monitor sources, and the lock groups upload rows only while waits exist. The backup-age alert now confirms 1.5 hours after the threshold is crossed, not 6. The HADR connection alert now fires within 15 minutes.

### Fixes {#fixes}

- **"Target is down" now means down.** A wrong or empty password, a revoked grant, a TLS or truststore problem, a missing driver, or a database quiesced against the monitoring user now shows as a *metric collection error* that says what to fix. Unreachable hosts and stopped instances still read Down. A quiesced or roll-forward-pending database counts as Up.
- **The ratio alerts can fire again.** The buffer-pool, catalog-cache and package-cache hit ratios, the sort-overflow ratio and the average lock wait are computed per collection interval, not from totals since the database was activated. After an upgrade they report from the second collection.
- **Collector connections are always released.** Every collection query has a timeout, 60 seconds by default, which the new optional **Query Timeout** property changes. Every query returns at most 10,000 rows.
- **Arithmetic and unit corrections** to `sync_index_read_rate`, `creation_to_assigning_ratio`, the HADR log positions (now in bytes), `tablespace_max_size` (-1 for no maximum) and `HadrTimeout` (now in seconds). A new `ValuesLive` column says when the HADR gap and lag values are last-known rather than live.
- **A `|` inside a collected value**, such as Db2's `||` operator in statement text, no longer corrupts the row.

## Feedback {#feedback}

Send findings (bugs, confusing metrics, missing thresholds, unclear documentation) to **helpdesk@integrationplumbers.io** or through the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/signin). Include the plug-in version (`emcli list_plugins_on_server`), the Enterprise Manager line (24ai or 13.5), the Db2 version (11.5 or 12.1) and topology, the metric group or console page involved, and any deploy log, agent log, or collection-error text. For a target that is not collecting, the Monitoring Readiness results are the fastest start: see [Troubleshooting](troubleshooting.md#support).

## Related

- [Upgrade notes](upgrade-notes.md): every change that needs operator action
- [Install and upgrade](install-and-upgrade.md#upgrade): the upgrade steps
- [Moving from the beta to GA](beta-pre-release.md): for Open Beta users
- [Getting started](getting-started.md): install the plug-in and add your first target
- [Changelog](changelog.md): every release in brief, with the release files and checksums
