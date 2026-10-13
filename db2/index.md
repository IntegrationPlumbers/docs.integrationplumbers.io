---
title: IBM Db2 Plug-in
nav_order: 0
---

# IBM Db2 Plugin

## Integration Plumbers

### Oracle Enterprise Manager Plug-in for IBM Db2 User Guide

*GA · `24.1.1.0.0` for Enterprise Manager 24ai · `13.5.2.0.0` for Enterprise Manager 13.5*  
*October 2026*

This is the first general-availability (GA) release of the plug-in. It ships as two plug-in builds with the same features: **24.1.1.0.0** for Enterprise Manager 24ai and **13.5.2.0.0** for Enterprise Manager 13.5. The two lines are versioned independently, so the numbers after `24.1` and `13.5` do not have to match. Enterprise Manager decides whether it will accept a plug-in from the toolkit it was built with, not from its version number, so the two are not interchangeable — install the build that matches your Enterprise Manager. Everything in this guide applies to both, except where a page says otherwise.

<details>
<summary>Legal Notice</summary>

Information in this document, including URL and other Internet Website references, is subject to change without notice. Unless otherwise noted, the companies, organizations, products, domain names, e-mail addresses, logos, people, places, and events depicted in examples herein are fictitious. No association with any real company, organization, product, domain name, e-mail address, logo, person, place, or event is intended or should be inferred.

Complying with all applicable copyright laws is the responsibility of the user. Without limiting the rights under copyright, no part of this document may be reproduced, stored in or introduced into a retrieval system, or transmitted in any form or by any means (electronic, mechanical, photocopying, recording, or otherwise), or for any purpose, without the express written permission of Integration Plumbers.

© 2026 Integration Plumbers. All rights reserved.

IBM and Db2 are trademarks of IBM Corporation, registered in many jurisdictions worldwide. Oracle and Enterprise Manager are trademarks of Oracle Corporation and/or its affiliates.

</details>

## Where to start

| If you want to | Go to |
| :--- | :--- |
| See what is in the GA release, and what to read first | [What's new](whats-new.md) |
| Move from the Open Beta to GA | [Moving from the beta to GA](beta-pre-release.md) |
| Install it and see a target, quickly | [Getting started](getting-started.md) |
| Get a licence key and work a guided evaluation | [Trial setup](trial.md) |
| Check your estate is ready | [Prerequisites](prerequisites.md) |
| Add your first Db2 database, and licence it | [Targets and properties](targets-and-properties.md) |
| Understand what a page is telling you | [Monitoring pages](monitoring-pages.md) |
| Confirm a standby pair is takeover-ready | [HADR monitoring](hadr-monitoring.md) |
| Turn on the compliance content | [Compliance standards](compliance-standards.md) |
| Tune what alerts you | [Alerts and thresholds](alerts-and-templates.md) |
| Run an admin job, locally or remotely | [Jobs](jobs-and-metric-extensions.md) |
| Fix something that is wrong | [Troubleshooting](troubleshooting.md) |

## What the plug-in monitors

The IBM Db2 plug-in makes **IBM Db2 for Linux, UNIX, and Windows (LUW)** a first-class Enterprise Manager target. A dedicated target type, `ip_db2_database` (shown in the console as **IBM DB2 Database**), models one monitored Db2 database and surfaces its availability, performance, storage, locking, high-availability, backup, and configuration posture in the same console, the same target navigation, and the same incident and notification rules you already use for the rest of your estate.

Collections run from a management agent over JDBC, entirely through Db2's `MON_GET_*` monitoring table functions and a handful of administrative catalog views — never the discontinued `SNAP_GET_*` interfaces. There is nothing to install on the database host for monitoring to work: the IBM Data Server Driver for JDBC and SQLJ ships bundled inside the plug-in's collector.

What you get once a target is up: a 5-minute availability check; general activity, per-agent and per-database performance, buffer pool and cache efficiency, sort and hash memory, lock-list use, and transaction-log and direct I/O; transaction-log, per-tablespace and storage-path storage with growth-rate forecasting; lock waits with full requester/holder detail, rolled up by table and by application, and the oldest open and idle-in-transaction units of work; role, state, sync mode, and log-position tracking for HADR pairs, including a takeover-readiness composite, a standby monitored as a standby, and a target that can follow the primary through a takeover; backup age plus a full backup/restore/load/reorg/rollforward history feed and the utilities running now; table maintenance (stale statistics, reorg candidates, invalid objects); top SQL statements by CPU time and by execution count, with their SQL text; a daily configuration snapshot across roughly 13 configuration groups; and 17 configuration, audit-posture and version-lifecycle compliance rules. Seven console pages present it, starting with a Home page health overview, and curated Warning and Critical thresholds ship enabled on the metrics that matter most, so a freshly added target raises real incidents without any tuning. Three remote administrative jobs and six Enterprise Manager runbooks (24ai) help you act on what you see.

**This is a brand-new product, not an upgrade of any prior Db2 plug-in.** Targets are added fresh — there is no migration of targets from another Db2 plug-in, Oracle's included. Because it registers under its own target-type name, it can run side by side with Oracle's bundled Db2 plug-in while you cut over database by database.

## Supported versions and platforms

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | 13.5 and 24ai |
| IBM Db2 LUW | **12.1**, certified at the Comprehensive level, and **11.5**, certified at the Basic level. Every metric collects on both; the level is the certification label Enterprise Manager shows in its plug-in catalog |
| Db2 LUW 11.1 and below | Not supported |
| Db2 topology | A single-partition database. Partitioned (DPF) and pureScale databases, and Db2 for z/OS, are not supported |
| Agent platforms | Linux x86-64 (64-bit), Microsoft Windows x86-64 (64-bit) |
| Amazon RDS for Db2 | Not certified — see [Troubleshooting](troubleshooting.md#rds-for-db2) |

**The plug-in does not require a matching driver.** The JDBC driver (type-4, `db2jcc4.jar`) is bundled and connects to both supported versions; see [Prerequisites](prerequisites.md#jdbc-driver).

**Enterprise Manager platform maturity.** Both builds are verified the same way: live deployment on an Enterprise Manager OMS and its agents, live Db2 collection, end-to-end licensing, and a walk through every console page, on Enterprise Manager 24ai and on Enterprise Manager 13.5. Install whichever matches your OMS; neither line is a preview of the other. The one feature that needs Enterprise Manager 24ai is the set of runbooks — see [Alerts and thresholds](alerts-and-templates.md#runbooks).

## Release status

This is a **general-availability** release, under the plug-in identity `ip.em.xdb2`. It is the first GA release, so there is no earlier GA version to upgrade from; GA updates after it upgrade in place.

If you ran the Open Beta (`ip.em.xdbb`), the GA plug-in is a different plug-in and is installed fresh, side by side with the beta, rather than upgraded over it — see [Moving from the beta to GA](beta-pre-release.md).

## Documentation

### Start here

- **IBM Db2 Plug-in** (this page) — what the plug-in does, and where every topic in this guide lives.
- [What's new](whats-new.md) — what to read first, the breaking changes, the known issue, and everything new in the GA release.
- [Moving from the beta to GA](beta-pre-release.md) — for Open Beta users: how to move to GA, and what changed.
- [Getting started](getting-started.md) — the shortest path from a downloaded archive to a Db2 target you can look at.
- [Trial setup](trial.md) — request a licence key, enter it on each target, then work the guided evaluation checklist.

### Set up

- [Prerequisites](prerequisites.md) — supported versions, the JDBC driver, network paths, the least-privilege monitoring user, and optional TLS.
- [Install and upgrade](install-and-upgrade.md) — download and verify the OPAR, import it, deploy it to the OMS and to each agent, and upgrade or uninstall.
- [Targets and properties](targets-and-properties.md) — add an `ip_db2_database` target, every target property, the EM CLI equivalent, and licensing.

### Reference

- [Monitoring pages](monitoring-pages.md) — a tour of the Home, Analysis, Performance, Storage, Backup History, SQL Analytics, and HADR pages.
- [HADR monitoring](hadr-monitoring.md) — role, state, sync mode, log-gap trending, the takeover-readiness composite, monitoring a standby, and following the primary through a takeover.
- [Compliance standards](compliance-standards.md) — the 17 rules in the configuration best-practices, version-lifecycle, and audit-posture standards, and how to associate them with targets.
- [Alerts and thresholds](alerts-and-templates.md) — every curated Warning/Critical default, how to tune one, and the runbooks.
- [Jobs](jobs-and-metric-extensions.md) — the local and remote administrative jobs, the credentials each needs, and the housekeeping job to run after every upgrade.
- [Troubleshooting](troubleshooting.md) — empty pages, failed jobs, and licence surprises, listed by the exact message you see.
- [Changelog](changelog.md) — what changed in each release, most recent first, with the beta history below.

## Support

If you need assistance with the IBM Db2 Plugin for Oracle Enterprise Manager:

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)
