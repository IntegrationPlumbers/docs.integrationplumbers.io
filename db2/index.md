---
title: IBM Db2 Plug-in
nav_order: 0
---

# IBM Db2 Plug-in

## Integration Plumbers

### Oracle Enterprise Manager Plug-in for IBM Db2 User Guide

*General Availability · `24.1.2.0.0` for Enterprise Manager 24ai · `13.5.3.0.0` for Enterprise Manager 13.5*  
*October 2026*

This guide covers release **24.1.2.0.0** for Enterprise Manager 24ai and **13.5.3.0.0** for Enterprise Manager 13.5, the general-availability (GA) release. The two builds have the same features. The lines are versioned independently, so the numbers after `24.1` and `13.5` do not have to match. Enterprise Manager decides whether it will accept a plug-in from the toolkit it was built with, not from its version number, so the two are not interchangeable: install the build that matches your Enterprise Manager. Everything in this guide applies to both, except where a page says otherwise.

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
| See what is in this release, and what to read first | [What's new](whats-new.md) |
| Upgrade from the initial release (24.1.1.0.0 / 13.5.2.0.0) | [Upgrade notes](upgrade-notes.md) |
| Install it and see a target, quickly | [Getting started](getting-started.md) |
| Get a licence key and work a guided evaluation | [Trial setup](trial.md) |
| Check your estate is ready | [Prerequisites](prerequisites.md) |
| Add your first Db2 database, and licence it | [Targets and properties](targets-and-properties.md) |
| Understand what a page is telling you | [Monitoring pages](monitoring-pages.md) |
| Look up a metric | [Metrics reference](metrics-reference.md) |
| Tune what alerts you | [Alerts and templates](alerts-and-templates.md) |
| Confirm a standby pair is takeover-ready | [HADR monitoring](hadr-monitoring.md) |
| Turn on the compliance content | [Compliance standards](compliance-standards.md) |
| Run an admin job, locally or remotely | [Jobs](jobs-and-metric-extensions.md) |
| Fix something that is wrong | [Troubleshooting](troubleshooting.md) |
| Move from the Open Beta | [Moving from the beta to GA](beta-pre-release.md) |

## What the plug-in monitors

The IBM Db2 plug-in makes **IBM Db2 for Linux, UNIX, and Windows (LUW)** a first-class Enterprise Manager target. Db2 databases and Db2 instances appear in the same console, the same target navigation, the same incident and notification rules, and the same compliance results you already use for the rest of your estate.

Collections run from a management agent over JDBC, through Db2's `MON_GET_*` monitoring table functions and a handful of administrative and catalog views, never the discontinued `SNAP_GET_*` interfaces. There is nothing to install on the database host for monitoring to work: the IBM Data Server Driver for JDBC and SQLJ ships bundled inside the plug-in's collector, and the monitoring user needs only `CONNECT` and `SQLADM`.

What you get once a target is up:

- availability, and the reason a database cannot be monitored when it answers but refuses the plug-in;
- performance: general activity, buffer pool and cache efficiency, sort and hash memory, instance memory and memory sets, where request time waits, latches, FCM, WLM workloads and service classes, and transaction-log and direct I/O;
- storage: table spaces with growth-rate forecasting, storage-path headroom, the transaction log and log archiving, and table and index maintenance (stale statistics, reorg candidates, unused indexes, invalid objects);
- locking: blocking chains down to the root blocker, lock waits rolled up by table and by application, the oldest open and idle-in-transaction units of work, and opt-in deadlock capture;
- SQL workload: top statements by CPU time and by executions with their SQL text, keyed by digest, and each statement's access plan on request;
- high availability: HADR role, state, sync mode and log positions, a takeover-readiness composite, a standby monitored as a standby, and a target that can follow the primary through a takeover;
- backup and recovery: backup age, the full backup, restore, load, reorg and rollforward history, and the utilities running now;
- partitioned (DPF) databases read across every member, and pureScale member and CF health;
- a daily configuration snapshot that feeds Enterprise Manager's configuration history and comparison, and 29 compliance rules on configuration, security, privileges, backup age, audit posture and version lifecycle.

Seventeen console pages present a database, and six an instance, starting with an Overview that says whether the database is healthy and whether monitoring works, and ending with a Monitoring Readiness page that checks the set-up and prints the statement that fixes each gap. Curated Warning and Critical thresholds ship enabled on the metrics that matter most, so a freshly added target raises real incidents without any tuning. Twelve job types, including three remote administrative jobs and a Back Up Database dialog, and six Enterprise Manager runbooks (24ai) help you act on what you see.

## Target types {#target-types}

| Target type | What it represents | How many you add |
| :--- | :--- | :--- |
| **IBM Db2 Database** (`ip_db2_database`) | One Db2 database: single-partition, partitioned (DPF), or pureScale (member and CF health only) | One per database you want to monitor. Each needs a licence key and counts toward its instance limit |
| **IBM Db2 Instance** (`ip_db2_instance`), new in 24.1.2.0.0 / 13.5.3.0.0 | One Db2 instance (database manager): its memory, agents, configuration, diagnostic log, and start and stop | Optional, one per instance. It needs a licence key but does not count toward its instance limit. See [Instance targets](targets-and-properties.md#instance-targets) |

**This is a brand-new product, not an upgrade of any prior Db2 plug-in.** Targets are added fresh: there is no migration of targets from another Db2 plug-in, Oracle's included. Because it registers under its own target-type names, it can run side by side with Oracle's bundled Db2 plug-in while you cut over database by database.

## Supported versions and platforms {#supported-versions}

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | 13.5 and 24ai |
| IBM Db2 LUW | **12.1**, certified at the Comprehensive level, and **11.5**, certified at the Basic level. Every metric collects on both; the level is the certification label Enterprise Manager shows in its plug-in catalog |
| Db2 LUW 11.1 and below | Not supported |
| Db2 topology | Single-partition and **partitioned (DPF)** databases. pureScale: member and CF health only, implemented, not lab-certified. Db2 for z/OS is not supported |
| Agent platforms | Linux x86-64 (64-bit), Microsoft Windows x86-64 (64-bit). AIX, Solaris, HP-UX and other agent platforms are not supported: the plug-in does not deploy to them |
| Federation and BLU (column-organized) databases | Monitored with the standard metric set; nothing specific to federation or column-organized tables is collected |
| Amazon RDS for Db2 | Not certified: see [Troubleshooting](troubleshooting.md#rds-for-db2) |
| Db2U (OpenShift, Kubernetes), IBM Db2 SaaS | Not certified: see [Db2U and IBM Db2 SaaS](targets-and-properties.md#db2u-saas) |
| Enterprise Manager MCP Server (24ai Release Update 12 and later) | IBM Db2 Database targets, their metric groups, units and incidents reach an AI client: see [EM MCP Server](mcp-server.md) |

**The plug-in does not require a matching driver.** The JDBC driver (type-4, `db2jcc4.jar`) is bundled and connects to both supported versions; see [Prerequisites](prerequisites.md#jdbc-driver).

**Enterprise Manager platform maturity.** Both builds come from the same source and carry the same features. The GA builds were verified the same way on each line: live deployment on an Enterprise Manager OMS and its agents, live Db2 collection, end-to-end licensing, and a walk through every console page, on Enterprise Manager 24ai and on Enterprise Manager 13.5. Install whichever matches your OMS; neither line is a preview of the other. Two features need Enterprise Manager 24ai: the runbooks ([Alerts and templates](alerts-and-templates.md#runbooks)) and the MCP server.

## Release status {#release-status}

This is the **general-availability** release, under the plug-in identity `ip.em.xdb2`, released 2026-10-23. It upgrades the initial release (24.1.1.0.0 / 13.5.2.0.0, released 2026-10-12) in place: if you run that release, read [Upgrade notes](upgrade-notes.md) first. Everything we know to be incomplete or unproven is in the limitations list on [What's new](whats-new.md#update-24-1-2) rather than left for you to discover.

If you ran the Open Beta (`ip.em.xdbb`), the released plug-in is a different plug-in and is installed fresh, side by side with the beta, rather than upgraded over it: see [Moving from the beta to GA](beta-pre-release.md).

**Give us feedback.** Send findings (bugs, confusing metrics, missing thresholds, unclear documentation) to support; [Troubleshooting](troubleshooting.md#support) says where and what to include. If you hit something that is not in the limitations list, we especially want to hear about it.

## Documentation

### Start here

- **IBM Db2 Plug-in** (this page): what the plug-in does, and where every topic in this guide lives.
- [What's new](whats-new.md): what is in this release, the upgrade notes in brief, and the known limitations, with the initial release below.
- [Getting started](getting-started.md): the shortest path from a downloaded archive to a Db2 target you can look at.
- [Trial setup](trial.md): request a licence key, enter it on each target, then work the guided evaluation checklist.

### Set up

- [Prerequisites](prerequisites.md): supported versions, the JDBC driver, network paths, the least-privilege monitoring user, TLS, Kerberos, sizing, and the optional collection throttle and batch collection.
- [Install and upgrade](install-and-upgrade.md): download and verify the OPAR, import it, deploy it to the OMS and to each agent, upgrade from the initial release, and uninstall.
- [Upgrade notes](upgrade-notes.md): every change in an upgrade that needs operator action.
- [Moving from the beta to GA](beta-pre-release.md): for Open Beta users.
- [Targets and properties](targets-and-properties.md): add a database or instance target, every property, the EM CLI equivalent, licensing, associations, and Db2U and IBM Db2 SaaS.
- [Target discovery](discovery.md): the local databases each agent host proposes as targets.

### Reference

- [Monitoring pages](monitoring-pages.md): a tour of every console page, from the Overview to Monitoring Readiness: seventeen on the database target and six on the instance target.
- [Metrics reference](metrics-reference.md): every metric group, column by column, with the alerts that ship enabled.
- [Alerts and templates](alerts-and-templates.md): every default threshold, how to tune one, the monitoring templates, the incident rule set, and the runbooks.
- [Jobs](jobs-and-metric-extensions.md): the local and remote administrative jobs, Explain, the corrective action, and the housekeeping and files the plug-in keeps on each agent.
- [Compliance standards](compliance-standards.md): the 29 rules in three standards, and how to associate them with targets.
- [HADR monitoring](hadr-monitoring.md): role, state, sync mode, log-gap trending, the takeover-readiness composite, monitoring a standby, and following the primary through a takeover.
- [EM MCP Server](mcp-server.md): what an AI assistant sees through Enterprise Manager's MCP server.
- [Troubleshooting](troubleshooting.md): empty pages, failed jobs, and licence surprises, listed by the exact message you see. A [troubleshooting guide for AI assistants](https://docs.integrationplumbers.io/db2/ai/troubleshooting.md) covers the same ground for your own assistant.
- [Changelog](changelog.md): what changed in each release, most recent first, with the beta history below.

## Support

If you need assistance with the IBM Db2 Plug-in for Oracle Enterprise Manager:

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)
