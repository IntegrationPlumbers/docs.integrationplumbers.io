---
title: IBM DB2 Plug-in
nav_order: 0
---

# IBM DB2 Plugin

## Integration Plumbers

### Oracle Enterprise Manager Plug-in for IBM Db2 User Guide

*Open Beta · `24.1.9.7.0` for Enterprise Manager 24ai · `13.5.9.2.0` for Enterprise Manager 13.5*
*September 2026*

This release ships as two plug-in builds with the same features: **24.1.9.7.0** for Enterprise Manager 24ai and **13.5.9.2.0** for Enterprise Manager 13.5. Enterprise Manager decides whether it will accept a plug-in from the toolkit it was built with, not from its version number, so the two are not interchangeable — install the build that matches your Enterprise Manager. Everything in this guide applies to both, except where a page says otherwise.

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
| Read the beta terms and what is and is not verified yet | [What's new](whats-new.md) |
| Install it and see a target, quickly | [Getting started](getting-started.md) |
| Get a beta licence key and work a guided evaluation | [Trial setup](trial.md) |
| Check your estate is ready | [Prerequisites](prerequisites.md) |
| Add your first Db2 database | [Targets and properties](targets-and-properties.md) |
| Understand what a page is telling you | [Monitoring pages](monitoring-pages.md) |
| Confirm a standby pair is takeover-ready | [HADR monitoring](hadr-monitoring.md) |
| Turn on the compliance content | [Compliance standards](compliance-standards.md) |
| Tune what alerts you | [Alerts and thresholds](alerts-and-templates.md) |
| Run an admin job, or clean up after an upgrade | [Jobs](jobs-and-metric-extensions.md) |
| Fix something that is wrong | [Troubleshooting](troubleshooting.md) |

## What the plug-in monitors

The IBM DB2 plug-in makes **IBM Db2 for Linux, UNIX, and Windows (LUW)** a first-class Enterprise Manager target. A dedicated target type, `ip_db2_database` (`ip_db2_database_beta` during the beta), models one monitored Db2 database and surfaces its availability, performance, storage, locking, high-availability, backup, and configuration posture in the same console, the same target navigation, and the same incident and notification rules you already use for the rest of your estate.

Collections run from a management agent over JDBC, entirely through Db2's `MON_GET_*` monitoring table functions and a handful of administrative catalog views — never the discontinued `SNAP_GET_*` interfaces. There is nothing to install on the database host for monitoring to work: the IBM Data Server Driver for JDBC and SQLJ ships bundled inside the plug-in's collector.

What you get once a target is up: a 5-minute availability check; general activity, per-agent and per-database performance, buffer pool and cache efficiency, sort and hash memory, and transaction-log and direct I/O; transaction-log and per-tablespace storage with growth-rate forecasting; lock waits with full requester/holder detail, rolled up by table and by application; role, state, sync mode, and log-position tracking for HADR pairs, including a takeover-readiness composite; backup age plus a full backup/restore/load history feed; top SQL statements by CPU time and by execution count; a daily configuration snapshot across roughly 13 configuration groups; and the first compliance content ever shipped for a Db2 plug-in. Curated Warning and Critical thresholds ship enabled on the metrics that matter most, so a freshly added target raises real incidents without any tuning.

**This is a brand-new product, not an upgrade of any prior Db2 plug-in.** Targets are added fresh — there is no migration of targets from another Db2 plug-in, Oracle's included. Because it registers under its own target-type name, it can run side by side with Oracle's bundled Db2 plug-in while you cut over database by database. See [Migrating from the Oracle Db2 plug-in](https://github.com/IntegrationPlumbers/ip-oem-db2-plugin/blob/main/docs/migration-from-oracle-plugin.md) for that path.

## Supported versions and platforms

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | 13.5 and 24ai |
| IBM Db2 LUW | **12.1** (primary, certified) and **11.5** (supported) |
| Db2 LUW below 11.5 (9.1–10.5) | Not supported |
| Agent platforms | Linux x86-64 (64-bit), Microsoft Windows x86-64 (64-bit) |
| Amazon RDS for Db2 | Documentation-verified compatibility; not yet lab-certified — see [Troubleshooting](troubleshooting.md#rds-for-db2) |

**The plug-in does not require a matching driver.** The JDBC driver (type-4, `db2jcc4.jar`) is bundled and connects to both certified versions; see [Prerequisites](prerequisites.md#jdbc-driver) if your site must supply IBM's own driver or licence JAR instead.

**Enterprise Manager platform maturity.** Live OMS deployment, live Db2 12.1 collection, and end-to-end licensing are lab-verified on Enterprise Manager 24ai, the platform this beta treats as its reference. The Enterprise Manager 13.5 build (`13.5.9.2.0`) is compiled from the same source and ships alongside it starting with this drop; give it the same install path in [Getting started](getting-started.md), and report anything that renders or collects differently than on 24ai — see [What's new](whats-new.md#beta-status) for the full verification matrix.

## Beta status

This is an **Open Beta** release: feature-complete for the scope in [What's new](whats-new.md), verified against a live Enterprise Manager 24ai OMS and a live Db2 12.1 database in our lab, and licensed per target so you can evaluate it against your own estate. It ships under its own plug-in identity, `ip.em.xdbb`, deliberately separate from the eventual GA plug-in (`ip.em.xdb2`) — see [What's new](whats-new.md#beta-identity) for what that means for you.

Beta means the release has not yet earned a production monitoring commitment, and that metric names, thresholds, and properties may still change in response to what beta users find. Give us feedback — bugs, confusing metrics, missing thresholds, unclear documentation — through your Integration Plumbers support contact, with the plug-in version (`emcli list_plugins_on_server`), the Db2 version, and the metric group or console page involved.

## Documentation

### Start here

- **IBM DB2 Plug-in** (this page) — what the plug-in does, and where every topic in this guide lives.
- [What's new](whats-new.md) — the beta terms, what is and is not verified yet, and everything in this release.
- [Getting started](getting-started.md) — the shortest path from a downloaded archive to a Db2 target you can look at.
- [Trial setup](trial.md) — request a beta licence key, enter it on each target, then work the guided evaluation checklist.

### Set up

- [Prerequisites](prerequisites.md) — supported versions, the JDBC driver, network paths, the least-privilege monitoring user, and optional TLS.
- [Install and upgrade](install-and-upgrade.md) — import the OPAR, deploy it to the OMS and to each agent, and move between beta drops.
- [Targets and properties](targets-and-properties.md) — add an `ip_db2_database` target, every target property, and the EM CLI equivalent.

### Reference

- [Monitoring pages](monitoring-pages.md) — a tour of the Home, Analysis, and Performance pages.
- [HADR monitoring](hadr-monitoring.md) — role, state, sync mode, log-gap trending, and the takeover-readiness composite.
- [Compliance standards](compliance-standards.md) — the configuration best-practices, version-lifecycle, and audit-posture standards, and how to associate them with targets.
- [Alerts and thresholds](alerts-and-templates.md) — every curated Warning/Critical default, and how to tune one.
- [Jobs](jobs-and-metric-extensions.md) — the six administrative job types, including the one to run after every upgrade.
- [Troubleshooting](troubleshooting.md) — empty pages, failed jobs, and licence surprises, listed by the exact message you see.
- [Changelog](changelog.md) — what changed in each beta drop, most recent first.

## Support

If you need assistance with the IBM DB2 Plugin for Oracle Enterprise Manager:

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)
