---
title: MySQL Plug-in
nav_order: 0
---

# MySQL Plug-in

## Integration Plumbers

### Oracle Enterprise Manager Plug-in for MySQL User Guide

*Open Beta · `24.1.9.N.0` for Enterprise Manager 24ai · `13.5.9.N.0` for Enterprise Manager 13.5*
*August 2026*

This release ships as two plug-in builds with the same features: one for Enterprise Manager 24ai and one for Enterprise Manager 13.5. Enterprise Manager decides whether it will accept a plug-in from the toolkit it was built with, not from its version number, so the two are not interchangeable — install the build that matches your Enterprise Manager. Everything in this guide applies to both.

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
| Read the beta terms and known limitations | [Open Beta notice](beta-pre-release.md) |
| Check your estate is ready | [Prerequisites](prerequisites.md) |
| Add your first instance | [Targets and properties](targets-and-properties.md) |
| Understand what a page is telling you | [Monitoring pages](monitoring-pages.md) |
| Look up a metric | [Metrics reference](metrics-reference.md) |
| Tune what alerts you | [Alerts and thresholds](alerts-and-thresholds.md) |
| Fix something that is wrong | [Troubleshooting](troubleshooting.md) |
| Know what changed | [What's new](whats-new.md) |

## Introduction

This chapter describes what the plug-in monitors and the platforms it supports.
**Topics:** 1.1 What the plug-in monitors · 1.2 Target types · 1.3 Supported MySQL versions and platforms · 1.4 Beta status
## 1.1 What the plug-in monitors
The plug-in makes MySQL a first-class Enterprise Manager target. MySQL servers, InnoDB Clusters and InnoDB ClusterSets appear in the same console, the same target navigation, the same incident and notification rules, and the same compliance results as the Oracle Database, host and middleware targets you already run. Collections run from a management agent over JDBC using an ordinary read-only MySQL account, so there is nothing to install on the database host and no second monitoring tool to operate.

What you get once a target is up: availability and the reason a server is down; server and workload performance, including InnoDB buffer pool, row lock waits, memory, file I/O, connections and per-table and per-user activity; statement performance from the Performance Schema digest tables, with Query Analyzer and its trends; replication health, from asynchronous replica lag through Group Replication consensus, messaging and certification, to ClusterSet disaster-recovery readiness; backup visibility built from what MySQL Enterprise Backup and Percona XtraBackup record in the server itself; daily configuration snapshots that feed Enterprise Manager's configuration history and comparison; and a security and administration posture scored by the MySQL compliance framework the plug-in ships. Nineteen thresholds arrive already set, so a freshly added target raises real incidents without any tuning.

## 1.2 Target types
The plug-in adds three target types. Which ones you use depends on how your MySQL estate is built — a standalone estate needs only the first.

| Target type | What it represents | How many you add |
|---|---|---|
| **MySQL Database** (`ip_mysql_database_beta`) | One MySQL server instance, standalone or a member of a cluster | One per server instance you want to monitor |
| **MySQL Cluster** (`ip_mysql_cluster_beta`) | One InnoDB Cluster, or the Group Replication group behind it, as a whole — membership, consensus, certification and backup source | One per cluster, pointed at a MySQL Router endpoint or at any member |
| **MySQL ClusterSet** (`ip_mysql_clusterset_beta`) | One InnoDB ClusterSet — a primary cluster, its replica clusters and the replication between them | One per ClusterSet, pointed at a MySQL Router endpoint or at the primary cluster |

The three types are independent of each other. A cluster or ClusterSet target does not create database targets for its members, and it does not need them: add whichever types match the questions you need answered. Most estates run database targets for every instance and one cluster or ClusterSet target above them, so that instance-level detail and group-level health both have somewhere to live.

> **Note:** Each target carries its own monitoring properties and credentials, including its own TLS Mode. Nothing is inherited from another target. See [4.1](targets-and-properties.md#target-properties).

## 1.3 Supported MySQL versions and platforms
**The plug-in does not block MySQL versions it has not seen.** MySQL releases are, in our experience, backward compatible for monitoring purposes, so a server newer than the matrix below is expected to work: add it, and the plug-in attempts full monitoring. We certify versions in this documentation as we validate them, prioritizing LTS releases — the series MySQL publishes dedicated release repositories for. If an uncertified version misbehaves, the metric groups it affects degrade to collection errors on those groups; they do not take monitoring of the target down as a whole.

Certification as of this build:

| Target | Tier | Status |
|---|---|---|
| MySQL 8.4 LTS | Comprehensive | **Certified** — primary reference platform |
| MySQL 9.7 LTS | Comprehensive | **Certified** (2026-07-28) |
| MySQL 8.0 | Basic | Supported and continuously exercised in our lab. Note 8.0 reached end of life in April 2026 — plan your upgrade |
| MySQL 9.5 / 9.6 / 26.x innovation releases | — | Expected to work; not yet certified |
| InnoDB Cluster (Group Replication, 8.4) | — | **Certified** (cluster target with member stats) |
| InnoDB ClusterSet | — | Validated on MySQL 9.5 commercial; 8.4 ClusterSet not yet certified |
| RDS / Aurora / Cloud SQL | — | Supported — added manually, see [4.4](targets-and-properties.md#autodiscovery); not yet certified |
| EM 24ai (24.1) | — | **Certified**, including the UI |
| EM 13.5 | — | Collection + compliance certified; console home and chart pages verified on `13.5.9.9.0` (2026-08-25); the 13.5 edition (`13.5.9.N.0`) is built from the same source and available with the beta |

**Enterprise Manager platform.** The build described in this guide is certified on Enterprise Manager 24ai (24.1), including its console pages, and that is the platform the beta covers.

> **Note:** An Enterprise Manager 13.5 edition (`13.5.9.N.0`) is built from the same source as the 24ai edition and is available with the beta, as the matrix row above notes. On 13.5, collection and compliance are certified in our lab and the console's home and chart pages were verified on `13.5.9.9.0` (2026-08-25); the remaining console pages have not been individually walked on 13.5, so treat 24ai as the reference platform and report any 13.5 rendering difference you see.

## 1.4 Beta status
This build is a beta. It is feature-complete for the scope listed in [10.1](whats-new.md#early-access-build-2026-08-18) — the three target types, their metric groups and pages, the shipped thresholds, the compliance framework, the Run EXPLAIN job and the connection options — and every one of those has been deployed and exercised against live MySQL targets in our lab before shipping. What remains for general availability is additive: broader certification, and features that extend this scope rather than change it. Everything we know to be incomplete or unproven is in the boundaries list at the end of 10.1 rather than left for you to discover.

Beta means the release has not yet earned a production monitoring commitment, and that metric names, thresholds and properties may still change in response to what beta users find. Any change that needs operator action is documented with its remediation before it ships.

**Give us feedback.** Send findings — bugs, confusing metrics, missing thresholds, unclear documentation — through your Integration Plumbers support contact. Include the plug-in version (`emcli list_plugins_on_server`), the MySQL version, and the metric group or console page involved. If you hit something that is not in the boundaries list in [10.1](whats-new.md#early-access-build-2026-08-18), we especially want to hear about it.

> **Note:** [Chapter 6](metrics-reference.md#metrics-reference) points to the generated metrics reference, which is produced from the plug-in's own metadata for this exact build. Where this guide and the reference differ on a column, a unit or a threshold, the reference is authoritative.
