---
title: What's new
nav_order: 1
---

# Release notes

**Topics:** 1.2 Open Beta - 24.1.9.13.0 / 13.5.9.13.0 (2026-09-25) · 1.1 Open Beta - 24.1.9.12.0 / 13.5.9.12.0 (2026-08-31)

## 1.2 Open Beta - 24.1.9.13.0 / 13.5.9.13.0 (2026-09-25)

The second beta drop. It is a month of work on top of drop 12, and it is worth taking even if drop 12 is running acceptably: several of the changes below alter what the numbers on the Queries and Performance pages **mean**, and a few fix cases where the previous drop reported something confidently wrong.

Same two editions from the same commit: `24.1.9.13.0` for Enterprise Manager 24ai and `13.5.9.13.0` for 13.5.

#### New

- **A Query History page**, the only page that takes a time range you choose. Which queries burned the most CPU between two times, to the minute, ranked and paged. Everything else in the plug-in shows you the present; this answers questions about an incident after it is over. See [Monitoring pages](monitoring-pages.md#query-history).
- **Top Queries by Memory Grant**, a sixth region on the Queries page and a new metric group, for finding the queries that are asking for memory rather than CPU.
- **Associated Services**, collected from `sys.dm_server_services`: the SQL Server services on the host with their state, start mode and service account, on a five minute schedule.
- **Database Composition**, the data-versus-log-versus-free breakdown per database, on the Databases page.
- **A per-database selector on the Databases page** that drives every region on it at once, instead of finding the same database's row separately in each table.
- **74 metric groups and 620 columns**, up from 71 and 527. The full list is in the [Metrics reference](metrics-reference.md).

#### Changed - read this before comparing numbers with drop 12

- **The query families now report per collection interval, not lifetime totals.** SQL Server's `dm_exec_query_stats` counters are cumulative since the plan was compiled, and drop 12 published them as they came. A query that ran hard last week and has been idle since therefore sat near the top of Top Queries by CPU forever. The plug-in now differences them between collections, so the figure is what that query cost during the interval and an idle query falls away. Top Queries by CPU, by Execution Count, by Memory Grant and Query Plan Statistics are all affected.
- **The wait statistics and file I/O families are differenced the same way**, for the same reason: `dm_os_wait_stats` and `dm_io_virtual_file_stats` are cumulative since service start, and drop 12 published the lifetime total as though it were current.
- **Queries are also grouped on a stable query hash**, so a plan recompiling mid-window no longer splits one query's history into two rows.
- **Cumulative performance counters are published as rates**, not as raw current values.
- **Cache hit ratios no longer blank on most collection cycles.** They are a rolling-window counter pair and were being differenced as though they were not.
- **A reading the plug-in does not know is now blank, not zero.** CPU, recovery point and queue readings on the AG Failover Readiness page reported `0` when the underlying value was unavailable, which reads as healthy. They now report unknown.
- **A database that has never been backed up says so**, instead of quoting an age computed from a sentinel date.
- **The 24 hour table regions carry a collection age line**, so a figure that is up to a day old says when it was taken.

**If you have tuned thresholds on any of the affected counters, re-check them.** A threshold set against a cumulative value will behave completely differently against a per-interval one. This is the single most disruptive change in the drop and it is deliberate: the previous behaviour was not answering a useful question.

#### Console

- **The left navigation is grouped and stays in place as the page scrolls**, so moving between pages on the longer surfaces no longer means scrolling back to the top.
- **The Performance page is 38% shorter** at the same information density, and the Analysis, Databases and Queries pages were reworked along the same lines: regions carded consistently, tables sized to their rows, and cells that no longer clip mid-character.
- **Pages stack sensibly at narrow browser widths** rather than truncating.

#### Fixed

- **TempDB contention collection failed whenever there was contention** to report, which is the only time it matters.
- **A `999999` sentinel reached customers in backup alert text.**
- **The licence card called the only broken key healthy** and printed a sentinel value.
- **Recent Deadlocks named the wrong database.** The victim database was resolved from a reused identifier rather than from the deadlock graph.
- **Create Index, Back Up, Restore and Delete Backup dialogs** had defects in field targeting and an over-long job hint.
- **A result field containing the plug-in's own delimiter** no longer corrupts the row around it.

#### Known limitations and boundaries

Every limitation listed under drop 12 below still applies. Four to add, three of which we found after drop 12 shipped.

- **Several "top" tables are not sorted by the measure they are named for.** "Top Queries by CPU" and "Top Queries by Execution Count" on the Queries page, "Query Plan Statistics" beside them, and "Top Sessions by CPU" on the Overview page each show ten rows, but not the ten highest. Enterprise Manager does not preserve the ordering a collection returns, and these pages do not re-sort them. The rows shown are drawn from the top 500 by the relevant measure, so they are a sample of the expensive end, not a ranking, and the first row is not the worst one. Treat them as an unordered sample until this is fixed. The same caveat applies to anything reading these metrics through EM CLI, the REST API or the MCP server. **The new Query History page is not affected** - it ranks in the query itself, so its ordering is real.
- **The backup compliance rule passes a database that has no backup at all.** The "Database Backup Is Stale" rule flags a database whose most recent backup is more than seven days old, but a database that has never been backed up is not flagged by it. Such a database does raise a metric alert saying it has no backup history, so the alert and the compliance result disagree. Trust the alert. This affects only the compliance rule, not the backup metrics or the alerting.
- **Query Plan Statistics shortens two column headings on a narrow window.** Below roughly 1400 pixels of browser width, the Statements and Executions headings on that one table are shown with an ellipsis. The values are unaffected and the table does not scroll sideways.
- **Query History counts a query from the second collection it appears in.** The figures are per-interval deltas, and a query the plug-in has not seen before has nothing to difference against, so its first appearance contributes nothing rather than a guess. Collections run every 15 minutes, which means a query that started and finished inside a single interval, and had never been seen before, can be missing from a range that covers it. A query that runs repeatedly is unaffected.

#### Upgrade notes

Deploy the new drop over the old one in the same way you installed it; beta drops are an in-place plug-in upgrade within `ip.em.xmsb`. Existing targets, credentials and thresholds carry forward. See [Install and upgrade](install-and-upgrade.md#upgrading).

Re-check any threshold you have tuned on the query, wait statistics, file I/O or performance counter families, for the reason given under Changed above.

## 1.1 Open Beta - 24.1.9.12.0 / 13.5.9.12.0 (2026-08-31)

The first release of the plug-in, and the release this guide describes. There is no earlier version, so everything below is new rather than changed.

It is a **separate plug-in** from the general-availability release: plug-in ID `ip.em.xmsb`, target type `ip_mssql_database_beta`. Beta and GA can be deployed to the same Enterprise Manager without colliding, and moving from beta to GA is a clean install rather than an upgrade. See the [Open Beta notice](beta-pre-release.md) for the terms and [Install and upgrade](install-and-upgrade.md#which-build) for which artifact matches your Enterprise Manager release.

Two editions are built from the same commit and differ only in version number: `24.1.9.12.0` for Enterprise Manager 24ai and `13.5.9.12.0` for Enterprise Manager 13.5 — the same features either way, not a separate product line.

#### Functionality

- **One plug-in and one target type for every supported SQL Server version**, 2016 through 2025, on both Linux and Windows agents. There is no separate build per SQL Server release and no separate story for Windows. See [Prerequisites](prerequisites.md#supported-versions).
- **69 metric groups**, covering availability, configuration, per-database space and files, performance counters, queries and the plan cache, deadlocks, indexes, backups, jobs, AlwaysOn availability groups, failover clusters and mirroring.
- **Eight console pages**: Overview, Databases, Performance, Queries, Deadlocks, Indexes, Analysis and AG Failover Readiness. See [Monitoring pages](monitoring-pages.md).
- **AG Failover Readiness**, which answers a question the built-in dashboards do not: if you failed over right now, what would it cost. One row per database per secondary, with synchronisation state, recovery point, recovery time, and redo and send queue sizes, folded into a readiness verdict. See [High availability](high-availability.md#failover-readiness).
- **14 default thresholds ship enabled**, applied per target at creation, so a target alarms from the moment it exists rather than after you tune it. See [Alerts and thresholds](alerts-and-thresholds.md#thresholds).
- **14 compliance rules** over configuration the plug-in already collects, ready to associate with no rule authoring. See [Compliance rules](compliance-rules.md#the-rules).
- **10 job types**, including native T-SQL backup and restore, delete backup, create index, availability-group failover, kill session, and service start, stop, pause and resume. See [Jobs](jobs.md#the-jobs).
- **TLS-first connections.** Encryption is on by default; the target property chooses whether the server certificate is also verified. `required` encrypts without validating the certificate, `verify` validates it against a truststore you supply, and `disabled` turns encryption off for instances that do not offer it. See [TLS connections](tls.md#modes).
- **A least-privilege monitoring login.** The plug-in does not need `sysadmin` to monitor. See [Credentials](credentials.md#grants) for the grant set and why. Jobs are the exception and have their own, larger requirements; see [Jobs](jobs.md#grants).
- **Per-interval rate metrics.** Several SQL Server counters are cumulative since the last service restart, and a raw cumulative value answers almost no useful question. The plug-in differences those between collections, and for anything collected per database it differences each database separately before summing, so a database attached or detached between two samples cannot masquerade as a spike or a lull.
- **Bulk onboarding through `emcli`**, for adding many targets at once rather than one at a time in the console. See [Targets and properties](targets-and-properties.md#adding).

#### Known limitations and boundaries

- **The certification matrix is not complete.** The Enterprise Manager 13.5 edition imports, deploys to the OMS and to agents, collects, and renders its console pages, verified on a live 13.5 OMS. It has not been exercised across the full SQL Server version matrix on that line. See [What is not yet verified](beta-pre-release.md#not-verified).
- **A backup job can report Succeeded after a late failure.** If a backup or restore fails partway through, after the operation has started, the job can return without raising an error and report Succeeded while leaving an incomplete file. Failures that occur before the operation starts, such as a missing database or a permission refusal, report correctly. Confirm backup files exist and are the expected size rather than relying on job status alone.
- **Two metric families return less detail on SQL Server 2016 and 2017**, both because the view that classifies a latched page by type arrived in 2019. TempDB contention collects, but its allocation-page and metadata-page waiter counts read zero and the advice cell is blank. Cluster nodes collects node names, but status, status description and current owner are blank. Read a zero or a blank in either as "not classifiable on this version", not as "nothing to report".
- **Volume free space collapses on Linux.** On Linux targets the Volume Free Space region on the Analysis page can report a single row with blank volume and label cells.
- **Windows-only surfaces are empty on Linux.** Registry settings and Windows service state have no Linux equivalent and report empty there rather than erroring.
- **Long chart windows can under-report.** On the Week and Month chart windows on the Performance page, a period containing a missed collection can render a lower value than actually occurred, or drop a series for that period. The 24 Hours window is unaffected.
- **Two Performance page charts do not offer a Real Time window.** Those values are measured over the collection interval, and a real-time poll would change what the scheduled collection records, so the window is not offered there.
- **Large instances are unmeasured.** The largest instance in our lab holds a normal developer database count. Collection overhead on an instance hosting a hundred or more databases has not been characterised.
- **Thresholds and intervals are provisional.** The 14 defaults are a starting point sized for lab workloads. Review them against your own service levels before relying on them, and see [Changing a threshold](alerts-and-thresholds.md#changing).
- **Some wide tables clip their rightmost columns** at narrower browser widths.
- **A new target looks sparse on its first day.** Server configuration and per-database space are on a 24 hour collection schedule. Most other data arrives far sooner: availability every minute, instance status every five, licence and backup age hourly. See [What a blank region means](monitoring-pages.md#blank).

#### Upgrade notes

There is no earlier build to upgrade from, so this is a first install. See [Install and upgrade](install-and-upgrade.md#installing).

Moving between beta drops and moving from beta to the general release are different operations. Beta to GA is a clean install onto a different plug-in ID, not an in-place upgrade; existing beta targets do not carry forward. See [Install and upgrade](install-and-upgrade.md#upgrading).

## Related

- [Open Beta notice](beta-pre-release.md) - the terms of the Open Beta programme and what is expected of you
- [Install and upgrade](install-and-upgrade.md#which-build) - which artifact matches your Enterprise Manager release
- [Monitoring pages](monitoring-pages.md) - what each of the nine console pages shows
- [Alerts and thresholds](alerts-and-thresholds.md) - the 14 thresholds and how to tune them
- [Troubleshooting](troubleshooting.md) - when something does not behave as described here
