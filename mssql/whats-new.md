---
title: What's new
nav_order: 1
---

# Release notes

**Topics:** 1.1 Open Beta - 24.1.9.12.0 / 13.5.9.12.0 (2026-08-31)

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
- [Monitoring pages](monitoring-pages.md) - what each of the eight console pages shows
- [Alerts and thresholds](alerts-and-thresholds.md) - the 14 thresholds and how to tune them
- [Troubleshooting](troubleshooting.md) - when something does not behave as described here
