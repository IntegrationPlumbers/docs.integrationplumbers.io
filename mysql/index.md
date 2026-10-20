---
title: MySQL Plug-in
nav_order: 0
---

# MySQL Plug-in

## Integration Plumbers

### Oracle Enterprise Manager Plug-in for MySQL User Guide

*General Availability · `24.1.10.0.0` for Enterprise Manager 24ai · `13.5.10.0.0` for Enterprise Manager 13.5*
*October 2026*

This release ships as two plug-in builds with the same features: one for Enterprise Manager 24ai and one for Enterprise Manager 13.5. Enterprise Manager decides whether it will accept a plug-in from the toolkit it was built with, not from its version number, so the two are not interchangeable. Install the build that matches your Enterprise Manager. Everything in this guide applies to both.

<details>
<summary>Legal Notice</summary>

Information in this document is subject to change without notice. Complying with all applicable copyright laws is the responsibility of the user. No part of this document may be reproduced or transmitted in any form without the express written permission of Integration Plumbers.

© 2026 Integration Plumbers. All rights reserved.

MySQL is a trademark of Oracle Corporation and/or its affiliates. Oracle and Enterprise Manager are trademarks of Oracle Corporation.

</details>

## Where to start

| If you want to | Go to |
| :--- | :--- |
| Install it and see a target, quickly | [Getting started](getting-started.md) |
| Check your estate is ready | [Prerequisites](prerequisites.md) |
| Add your first instance | [Targets and properties](targets-and-properties.md) |
| Understand what a page is telling you | [Monitoring pages](monitoring-pages.md) |
| Look up a metric | [Metrics reference](metrics-reference.md) |
| Tune what alerts you | [Alerts and thresholds](alerts-and-thresholds.md) |
| Fix something that is wrong | [Troubleshooting](troubleshooting.md) |
| Know what changed | [What's new](whats-new.md) |

## Introduction

This chapter describes what the plug-in monitors and the platforms it supports.
**Topics:** 1.1 What the plug-in monitors · 1.2 Target types · 1.3 Supported MySQL versions and platforms · 1.4 Release status
## 1.1 What the plug-in monitors
The plug-in makes MySQL a first-class Enterprise Manager target. MySQL servers, InnoDB Clusters and InnoDB ClusterSets appear in the same console, the same target navigation, the same incident and notification rules, and the same compliance results as the Oracle Database, host and middleware targets you already run. Collections run from a management agent over JDBC using an ordinary read-only MySQL account, so there is nothing to install on the database host and no second monitoring tool to operate.

What you get once a target is up:

- availability, and the reason a server is down;
- server and workload performance: InnoDB buffer pool, row lock waits, memory, file I/O, connections, and per-table and per-user activity;
- statement performance from the Performance Schema digest tables, with Query Analyzer and its trends;
- replication health, from asynchronous replica lag through Group Replication consensus, messaging and certification, to ClusterSet disaster-recovery readiness;
- backup visibility built from what MySQL Enterprise Backup and Percona XtraBackup record in the server itself;
- daily configuration snapshots that feed Enterprise Manager's configuration history and comparison;
- a security and administration posture scored by the MySQL compliance framework the plug-in ships.

Twenty-two thresholds arrive already set, so a freshly added target raises real incidents without any tuning.

## 1.2 Target types
The plug-in adds three target types. Which ones you use depends on how your MySQL estate is built. A standalone estate needs only the first.

| Target type | What it represents | How many you add |
|---|---|---|
| **MySQL Database** (`ip_mysql_database`) | One MySQL server instance, standalone or a member of a cluster | One per server instance you want to monitor |
| **MySQL InnoDB Cluster** (`ip_mysql_cluster`) | One InnoDB Cluster, or the Group Replication group behind it, as a whole: membership, consensus, certification and backup source | One per cluster, pointed at a MySQL Router endpoint or at any member |
| **MySQL InnoDB ClusterSet** (`ip_mysql_clusterset`) | One InnoDB ClusterSet: a primary cluster, its replica clusters and the replication between them | One per ClusterSet, pointed at a MySQL Router endpoint or at the primary cluster |

The three types are independent of each other. A cluster or ClusterSet target does not create database targets for its members, and it does not need them: add whichever types match the questions you need answered. Most estates run database targets for every instance and one cluster or ClusterSet target above them, so that instance-level detail and group-level health both have somewhere to live.

> **Note:** Each target carries its own monitoring properties and credentials, including its own TLS Mode. Nothing is inherited from another target. See [4.1](targets-and-properties.md#41-target-properties).

## 1.3 Supported MySQL versions and platforms
**The plug-in does not block MySQL versions it has not seen.** MySQL releases are, in our experience, backward compatible for monitoring purposes, so a server newer than the matrix below is expected to work: add it, and the plug-in attempts full monitoring. We certify versions in this documentation as we validate them, prioritizing LTS releases, the series MySQL publishes dedicated release repositories for. If an uncertified version misbehaves, the metric groups it affects degrade to collection errors on those groups; they do not take monitoring of the target down as a whole.

Certification as of this build:

| Target | Tier | Status |
|---|---|---|
| MySQL 8.4 LTS | Comprehensive | **Certified** (primary reference platform) |
| MySQL 9.7 LTS | Comprehensive | **Certified** (2026-07-28) |
| MySQL 8.0 | Basic | Supported and continuously exercised in our lab. Note 8.0 reached end of life in April 2026; plan your upgrade |
| MySQL 9.5 / 9.6 / 26.x innovation releases | | Expected to work; not yet certified |
| InnoDB Cluster (Group Replication, 8.4) | | **Certified** (cluster target with member stats) |
| InnoDB ClusterSet | | Validated on MySQL 9.5 commercial; 8.4 ClusterSet not yet certified |
| Amazon RDS for MySQL 8.4 | Comprehensive | **Certified** (2026-09-09, RDS MySQL 8.4.11), added manually, see [4.4](targets-and-properties.md#44-autodiscovery); managed-service notes there |
| Aurora MySQL / Cloud SQL / Azure Database for MySQL | | Supported, added manually, see [4.4](targets-and-properties.md#44-autodiscovery); not yet certified |
| EM 24ai (24.1) | | **Certified**, including the UI |
| EM 13.5 | | **Certified**, the MySQL Database, MySQL InnoDB Cluster and MySQL InnoDB ClusterSet target types with the same features as on 24ai; console pages checked as in the note below. Supported in GA and GA Update 1; not built for releases after that |

**Enterprise Manager platform.** This release is certified on Enterprise Manager 24ai (24.1), including its console pages, and on Enterprise Manager 13.5 as the note below describes. Enterprise Manager 24ai is the reference platform.

> **Note:** The Enterprise Manager 13.5 edition is built from the same source as the 24ai edition and ships with this release. On 13.5, collection and compliance are certified in our lab. The GA proof on 13.5 (2026-10-08 and 09) walked all 28 console pages of the three target types, including the MySQL InnoDB Cluster and MySQL InnoDB ClusterSet pages, and none raised an Enterprise Manager error dialog. On 13.5, some tables keep the column widths that Enterprise Manager's own table component gives them, rather than being sized to their content as on 24ai. Treat 24ai as the reference platform and report any 13.5 rendering difference you see.

> **Note:** **Enterprise Manager 13.5 support ends after GA Update 1.** The 13.5 edition is supported in GA and in GA Update 1 (expected later in 2026), and it is not built for releases after that, because Oracle's Extended Support for Enterprise Manager 13.5 ends on 2026-12-31. Releases after Update 1 are built for Enterprise Manager 24ai only. Plan the move of your Enterprise Manager to 24ai before then.

## 1.4 Release status
This is the generally available (GA) release of the plug-in. It covers the three target types, their metric groups and pages, the shipped thresholds, the compliance framework, the Run EXPLAIN job and the connection options ([10.4](whats-new.md#104-general-availability-2026-10-23) lists what this release adds to the earlier builds). Every one of those has been deployed and exercised against live MySQL targets in our lab before shipping. Everything we know to be incomplete or unproven is in the boundaries list in [10.4](whats-new.md#104-general-availability-2026-10-23) rather than left for you to discover.

Earlier builds do not upgrade in place to this release: install it fresh and create the targets new ([3.4](install-and-upgrade.md#34-upgrading)). The onboarding script moves an existing estate across ([4.7](targets-and-properties.md#47-bulk-onboarding-and-migration)).

**Give us feedback.** Send findings (bugs, confusing metrics, missing thresholds, unclear documentation) through your Integration Plumbers support contact. Include the plug-in version (`emcli list_plugins_on_server`), the MySQL version, and the metric group or console page involved. If you hit something that is not in the boundaries list in [10.4](whats-new.md#104-general-availability-2026-10-23), we especially want to hear about it.

> **Note:** [Chapter 6](metrics-reference.md#metrics-reference) points to the generated metrics reference, which is produced from the plug-in's own metadata for this exact build. Where this guide and the reference differ on a column, a unit or a threshold, the reference is authoritative.
