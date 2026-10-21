---
title: What's new
nav_order: 1
---

# Release notes

**Topics:** 1.3 General availability - 24.1.1.0.0 / 13.5.1.0.0 (2026-10-23) · 1.2 Open Beta - 24.1.9.13.0 / 13.5.9.13.0 (2026-09-25) · 1.1 Open Beta - 24.1.9.12.0 / 13.5.9.12.0 (2026-08-31)

## 1.3 General availability - 24.1.1.0.0 / 13.5.1.0.0 (2026-10-23) {#ga}

The first generally available release of the plug-in, `ip.em.xmss` with target type `ip_mssql_database`: build `24.1.1.0.0` for Enterprise Manager 24ai and build `13.5.1.0.0` for Enterprise Manager 13.5, built from the same commit.

It is a fresh install. The Open Beta shipped as a separate plug-in (`ip.em.xmsb`), so no beta build upgrades in place to this one and nothing the beta wrote into the repository carries over: no metric history, incidents, compliance results or thresholds. Install it, create the targets new, re-enter any threshold you tuned, then undeploy the beta - [Moving from the Open Beta](install-and-upgrade.md#from-beta) has the steps. Open Beta licence keys stop working on 2026-10-31. The notes below compare the release with Open Beta drop 13; the two drop sections after them are kept as they were published.

#### What the release contains

- **One plug-in and one target type** for SQL Server 2016 through 2025 on Linux and Windows agents. Every metric collects over T-SQL and DMVs, so the plug-in runs against SQL Server on Linux with no WMI and no Windows agent; Windows-only surfaces report empty there rather than erroring. See [Prerequisites](prerequisites.md#supported-versions).
- **78 metric groups**: availability, configuration, per-database space, files and composition, performance counters, queries and the plan cache, Query Store, waits, file I/O, blocking, deadlocks, indexes, backups, SQL Server Agent jobs, security update status, AlwaysOn availability groups, failover clusters, mirroring, licence and collector status. The full list is in the [Metrics reference](metrics-reference.md).
- **14 console pages**: Overview, Databases, Performance, Counters, Current Queries, Query History, Blocking, Waits, File I/O, Deadlocks, Indexes, Capacity, AG Failover Readiness and License Info, with the Create Index, Back Up, Schedule Backup, Restore and Delete Backup History dialogs. Query History, Blocking, Waits, File I/O and AG Failover Readiness read a start and end time you choose. See [Monitoring pages](monitoring-pages.md).
- **20 default thresholds** enabled per target at creation, all site-tunable ([Alerts and thresholds](alerts-and-thresholds.md#thresholds)); **14 compliance rules** ([Compliance rules](compliance-rules.md)); **11 job types** including native T-SQL backup and restore with no `xp_cmdshell`, Show Query Plan, kill session and availability-group failover ([Jobs](jobs.md)).
- **A least-privilege monitoring login** and **TLS-first connections**, with a verify mode against a truststore you supply. See [Credentials](credentials.md) and [TLS connections](tls.md).
- **AG Failover Readiness**: per-database recovery point and recovery time and a synchronisation verdict, live and over a range. See [High availability](high-availability.md).
- **Every metric group is readable by an AI client** through the Enterprise Manager MCP Server on 24ai Release Update 12 and later; [AI clients and the MCP Server](mcp-server.md) says what an assistant sees and what it cannot reach.

#### New since Open Beta drop 13

- **Four more pages that take a time range.** [Blocking](monitoring-pages.md#blocking) shows sessions blocked now and the top 50 blocked requests between two times, with the SQL text of both sides. [Waits](monitoring-pages.md#waits) shows the wait types the instance spent its time on over a range. [File I/O](monitoring-pages.md#file-io) shows what each database file read and wrote over a range, with average latency per operation. The [AG Failover Readiness](monitoring-pages.md#ag-failover) page adds the replication figures and the HADR wait types over a range. [Query History](monitoring-pages.md#query-history) gains ranking by memory granted, a view of queries whose plan changed, two Query Store views, a Source column on every table, and a Show plan action.
- **Query Store.** Two new metric groups read SQL Server's Query Store where it is on: Query Store Status per database, and per-interval plan statistics that survive plan-cache eviction and restarts. A third, Query Store Plan Regression, compares each query's current plan with its previous one and ships a default alert on the CPU ratio (Warning 2, Critical 5). Current Queries gains a Query Store panel.
- **Show Query Plan job**: one execution plan's XML to the job output, by Query Store plan id or by plan hash, offered from Query History as a `.sqlplan` download. See [Jobs](jobs.md#the-jobs).
- **Schedule Backup** on the Databases page: the backup job on an Enterprise Manager schedule, one-time or daily. See [Jobs](jobs.md#the-jobs).
- **A [Counters](monitoring-pages.md#counters) page** holds the five performance-counter tables that were on Performance. Current Queries gains a rows-per-page selector, captions that state the interval each column covers and flag a late collection, and a Copy button for query text.
- **Collector Status**: per metric group, one word from a closed set (`OK`, `NOT_CONFIGURED`, `NOT_COLLECTED_YET`, `NO_DATA`, `COLLECTION_ERROR`, `DISABLED`) with a reason, so an empty group can be told apart from a feature that is not set up and a collection that is failing, and a CRITICAL incident when a group's collection keeps failing. See [Troubleshooting](troubleshooting.md#collector-status).
- **Security Update Status**: the instance build against Microsoft's latest security update, with the oldest missed update the days-behind count starts from and a flag for builds outside the reference table.
- **Database free space alerts on headroom**, the space the data files can still grow into on their volume, instead of the free share of allocated space. Volume Space gains a low-space alert; File I/O Statistics gains per-file latency columns with thresholds (Warning 50 ms, Critical 100 ms); master and model drop out of the two file I/O groups unless you list them. See [Alerts and thresholds](alerts-and-thresholds.md#understanding).
- **Every label says what its value means**, every group carries at least one number column, and a label whose value can be blank names the column that says why, so an AI client reading through the MCP Server is not handed a guess. The [AI clients and the MCP Server](mcp-server.md) page is new.
- **Last Execution on the query groups and Last Attempt on Collector Status are numbers**, not changing strings, which stops the repository's string history growing by hundreds of thousands of rows a day.
- **The console moved onto the Integration Plumbers console standard**: one page frame, one colour and type scale, grouped navigation that stays in place as the page scrolls; the Analysis page is named Capacity. The CPU tile and the Processor Load chart say when system CPU is not available (SQL Server 2017 to 2022 on Linux) and chart SQL Server's own CPU instead of a blank.
- **Failover cluster instances**: target by the virtual name, instance and port; collection survives a failover both ways.
- **78 metric groups**, up from 74 in drop 13.

#### Fixed since drop 13

- **The Current Queries tables rank in the query**, so page 1 is the real top 10. The Overview page's Top Sessions table is still an unordered sample (below).
- **A SQL text over 4000 bytes no longer causes the repository loader to reject the row and about 50 of its neighbours**; long text columns are capped at the repository's limit.
- **Interval metrics populate for a `HOST\INSTANCE` target on a Windows agent.**
- **Locks**: a session holding several locks that share the group key no longer fails the whole collection.
- **Index Fragmentation applies its 1,000-page floor to the whole index**, so partitioned and LOB indexes are sized in full.
- **A metric fault shows as a note in the region** instead of a modal dialog, the error dialog scrolls, and the backup path placeholder reads whole.
- **A collector that read its credentials before the agent had written them** ran as an empty user and the target went Down; the reader now waits for the credential block.

#### Security

- **Host, Port, Named Instance and database name are validated before the connection URL is built**, so a target property cannot add driver options to the connection. A target whose value breaks the rules fails its collections with an error naming the property.
- **A job parameter value can no longer add, repeat or reorder an argument** the job passes to the agent; a comma typed into a value is kept as part of the value, so a comma-separated Create Index column list reaches the job whole for the first time. A rejected value fails the job step with the reason naming the parameter.

#### Known limitations and boundaries

Every open defect you could meet, and every boundary that is by design. The defects are logged and scheduled.

Defects:

- **A backup job can report Succeeded after a late failure.** If a backup or restore fails partway through, after the operation has started, the job can return without raising an error and report Succeeded while leaving an incomplete file. Failures before the operation starts, such as a missing database or a permission refusal, report correctly. Confirm backup files exist and are the expected size rather than relying on job status alone.
- **Volume free space collapses on Linux.** On Linux targets the Volume Free Space region shows a single row with blank volume and label cells and the smallest free space, so the volume low-space alert fires without naming the volume. Database and file-level space reporting is unaffected.
- **Long chart windows can under-report.** On the Week and Month chart windows a period containing a missed collection can render a lower value than occurred, or drop a series for that period. The 24 Hours window is unaffected.
- **Some wide tables clip their rightmost columns** at narrower browser widths, without a horizontal scroller. The data is collected correctly and is visible on the All Metrics page.
- **The Overview page's Top Sessions by CPU table is not sorted by CPU.** It shows ten sessions drawn from the top 500, not the ten highest; treat it as an unordered sample. The Current Queries and Query History tables rank in the query and are not affected. Anything reading the stored query groups through EM CLI, the REST API or the MCP Server must sort the rows it gets back.
- **The backup compliance rule passes a database that has no backup at all.** The "Database Backup Is Stale" rule flags a database whose most recent backup is more than seven days old, but one that has never been backed up is not flagged. Such a database does raise a metric alert saying it has no backup history; trust the alert.
- **Query Plan Statistics shortens two column headings on a narrow window.** Below roughly 1400 pixels of browser width the Statements and Executions headings on that one table show an ellipsis. The values are unaffected.
- **Top Queries by Cumulative Memory Grant is slightly wider than its region.** On the Current Queries page at a browser width of about 1570 pixels that table runs about 70 pixels past its region, so the page scrolls sideways a little to reach its last column.
- **An error dialog can appear on the Overview page of a target whose SQL Server is unreachable.** About a second after the page loads, Enterprise Manager's own console framework shows "Unexpected Error - Error during operation: BatchService.submitBatchRequest". Dismiss it; the page's regions carry on and nothing is lost. It is raised by the framework, not the plug-in, and does not appear once the instance is reachable.
- **Non-ASCII text shows as question marks when the agent runs without a UTF-8 locale.** Every non-ASCII character in collected text - database, login and host names, SQL text, file paths - arrives as `?`; numbers and ASCII text are unaffected. The UTF-8 locale is a prerequisite; restart the agent from a shell where it is set.

By design:

- **Two metric families return less detail on SQL Server 2016 and 2017**, because the view that classifies a latched page by type arrived in 2019. TempDB contention collects, but its allocation-page and metadata-page waiter counts read zero and the advice cell is blank. Cluster nodes collects node names, but status, status description and current owner are blank. Read a zero or a blank in either as "not classifiable on this version", not as "nothing to report".
- **CPU utilization is not reported on SQL Server 2017, 2019 and 2022 on Linux.** The operating system's idle counter returns nothing usable there, so CPU Utilization, System Idle and Other Process Utilization are blank rather than zero, the CPU threshold does not fire, and the CPU tile and chart show SQL Server's own process CPU instead. CPU Counters Available is 0 on those instances and 1 where the idle reading is real; it also reads 0 for a host that is genuinely 100% busy, because the two cannot be told apart at the source. Read the flag before treating a zero as a measurement; some API clients render a blank number as 0.
- **Windows-only surfaces are empty on Linux.** Registry settings, Windows services and cluster detail report empty rows on a Linux-hosted instance rather than erroring, as do the availability-group and failover-cluster groups on a standalone instance.
- **Two Performance page charts do not offer a Real Time window.** Those values are measured over the collection interval, and a real-time poll would change what the scheduled collection records.
- **Per-interval values are blank when there is nothing to measure against**: the first collection after a deploy, a target add or an instance restart, and a counter reset. The query, wait, file I/O and performance-counter families are all per-interval, so a query the plug-in has not seen before contributes nothing to a range on its first appearance, and a query that started and finished inside one 15-minute interval and was never seen again can be missing from a range that covers it.
- **Query Store plan statistics start from the deploy.** The first collection records the server's current time and stores only intervals that close after it, not the history Query Store already holds; most 15-minute collections are empty by design, because Query Store closes an interval every 60 minutes by default. The groups read only databases where Query Store is on, which before SQL Server 2022 is a choice per database.
- **A new target looks sparse on its first day.** Instance configuration and per-database space collect every 24 hours; the Overview page takes a one-off live reading of the two slowest so they appear at once, with a note saying the data is a live read. Everything else fills in as its schedule comes round. See [What a blank region means](monitoring-pages.md#blank).
- **The default thresholds are starting points.** Review all 20 against your own service levels before relying on them, in particular the File I/O latency defaults, which a site on fast storage may want lower. See [Changing a threshold](alerts-and-thresholds.md#changing).
- **Windows Integrated Authentication is supported on a Windows agent but not exercised in our lab**, which has no instance configured for it. SQL authentication is exercised on both agent platforms.
- **Large instances are unmeasured.** The largest instance in our lab holds a normal developer database count; collection overhead at a hundred or more databases on one instance has not been characterised.
- **Enterprise Manager 13.5 is certified for deployment, not across SQL Server versions.** The 13.5 build imports, deploys to the management server and to an agent, collects and renders its console pages on a live 13.5 OMS against SQL Server 2022; the 24ai build is exercised across SQL Server 2016 through 2025. Treat 24ai as the reference platform on that point.
- **There is no in-place upgrade from the Open Beta**, by design, and because this is the first general release there is no earlier general release to upgrade from, so the in-place upgrade path has not been exercised yet.
- **The Enterprise Manager MCP Server needs 24ai Release Update 12 or later.** [AI clients and the MCP Server](mcp-server.md) says what an assistant sees, how to connect one and where the boundary is.

#### Upgrade notes

None for an in-place upgrade, because there is none: this release is a fresh install. Coming from a beta drop, every threshold is re-entered against the new targets, so check what each one means now before copying a number across; the Changed section of drop 13 below and the alert changes above are where the meanings moved.

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

It is a **separate plug-in** from the general-availability release: plug-in ID `ip.em.xmsb`, target type `ip_mssql_database_beta`. Beta and GA can be deployed to the same Enterprise Manager without colliding, and moving from beta to GA is a clean install rather than an upgrade. See the [Open Beta ended](beta-pre-release.md) page for where the beta terms went and [Install and upgrade](install-and-upgrade.md#which-build) for which artifact matches your Enterprise Manager release.

Two editions are built from the same commit and differ only in version number: `24.1.9.12.0` for Enterprise Manager 24ai and `13.5.9.12.0` for Enterprise Manager 13.5 — the same features either way, not a separate product line.

#### Functionality

- **One plug-in and one target type for every supported SQL Server version**, 2016 through 2025, on both Linux and Windows agents. There is no separate build per SQL Server release and no separate story for Windows. See [Prerequisites](prerequisites.md#supported-versions).
- **71 metric groups**, covering availability, configuration, per-database space and files, performance counters, queries and the plan cache, deadlocks, indexes, backups, jobs, AlwaysOn availability groups, failover clusters and mirroring.
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

- **The certification matrix is not complete.** The Enterprise Manager 13.5 edition imports, deploys to the OMS and to agents, collects, and renders its console pages, verified on a live 13.5 OMS. It has not been exercised across the full SQL Server version matrix on that line. That boundary is restated for the general release above.
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

- [Open Beta ended](beta-pre-release.md) - the beta has ended; how to move to the general release
- [Install and upgrade](install-and-upgrade.md#which-build) - which artifact matches your Enterprise Manager release
- [Monitoring pages](monitoring-pages.md) - what each of the 14 console pages shows
- [Alerts and thresholds](alerts-and-thresholds.md) - the 20 default thresholds and how to tune them
- [Troubleshooting](troubleshooting.md) - when something does not behave as described here
