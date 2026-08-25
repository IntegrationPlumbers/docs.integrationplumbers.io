---
title: PostgreSQL Plug-in
nav_order: 0
---

# PostgreSQL Plugin

![Logo](images/logo.png){: style="border:none;box-shadow:none"}

## Integration Plumbers

### Oracle Enterprise Manager Plugin for PostgreSQL User Guide

*Version 13.5.15.0.0*  
*August 2026*

<details>
<summary>Legal Notice</summary>

Information in this document, including URL and other Internet Website references, is subject to change without notice. Unless otherwise noted, the companies, organizations, products, domain names, e-mail addresses, logos, people, places, and events depicted in examples herein are fictitious. No association with any real company, organization, product, domain name, e-mail address, logo, person, place, or event is intended or should be inferred.

Complying with all applicable copyright laws is the responsibility of the user. Without limiting the rights under copyright, no part of this document may be reproduced, stored in or introduced into a retrieval system, or transmitted in any form or by any means (electronic, mechanical, photocopying, recording, or otherwise), or for any purpose, without the express written permission of CN Software LLC.

CN Software LLC may have patents, patent applications, trademarks, copyrights, or other intellectual property rights covering the subject matter in this document. Except as expressly provided in any written license agreement from CN Software LLC, the furnishing of this document does not give you any license to these patents, trademarks, copyrights, or other intellectual property.

© 2026 CN Software LLC. All rights reserved.

PostgreSQL and the "Slonik" logo are trademarks of the PostgreSQL Community Association of Canada and are used here with permission.

</details>

The PostgreSQL plug-in monitors PostgreSQL instances from inside Oracle Enterprise Manager: close to 200 metrics per instance, with thresholds, metric history, and incidents on targets you manage alongside everything else in your estate. On top of that it adds five advisory pages. **Plan Analysis**, **Plan Drift Advisor**, **Workload History**, **Index Advisor**, and **Vacuum Advisor** each name the query, index, or table at fault, then hand you SQL to review and run in your own tooling.

## Choose your path

**Existing customers — [What's new in 13.5.15](whats-new.md).** Start here if you monitor PostgreSQL with 13.5.12 today. Your targets, console, and alert routing carry forward untouched, and the page covers the new advisor pages and metrics plus the one database-side prerequisite the plan pages need.

**New customers — [Getting started](getting-started.md).** Start here if the plug-in is not yet deployed. Six steps take an empty Enterprise Manager to a console with real data in it, each with what to do and how you know it worked.

**Evaluating — [Trial setup](trial.md).** Start here if you are deciding whether to buy. A trial is the whole product on your own OMS against your own instances, with a guided checklist that exercises every advisor in about a week. Request a key at [https://integrationplumbers.io/postgresql-plugin/trial](https://integrationplumbers.io/postgresql-plugin/trial).

Whichever path you take, the plug-in never applies a recommendation for you, and the only EXPLAIN that executes a statement is the Fix Workbench on **Plan Drift Advisor**, on your click. The product's one other EXPLAIN, the Index Advisor's HypoPG simulation, plans a synthetic lookup with `EXPLAIN (FORMAT JSON)` and executes nothing. Advisor findings publish as standard Enterprise Manager metrics, so they raise alerts and route through the notification connectors you already have bound. The plug-in supports PostgreSQL 14 to 18 on Enterprise Manager 13.5 and 24ai.

## Documentation

### Start here

- **PostgreSQL Plug-in** (this page) — what the plug-in does, and where every topic in this guide lives.
- [What's new in 13.5.15](whats-new.md) — everything added since 13.5.12, why the upgrade is additive, and the one prerequisite the new plan pages need.
- [Getting started](getting-started.md) — six steps from an empty Enterprise Manager to a console with real data, each with a check that tells you it worked.
- [Trial setup](trial.md) — request a trial key, enter it on each target, then work the checklist that exercises every advisor.

### Set up

- [Prerequisites](prerequisites.md) — the monitoring role, `auto_explain` and its server log read grant, and the optional extensions individual features need.
- [Install and upgrade](install-and-upgrade.md) — import the OPAR, deploy it to the OMS and to each agent, and upgrade an existing 13.5.x deployment in place.
- [Targets and properties](targets-and-properties.md) — add PostgreSQL Database and Cluster targets, every target property, Patroni REST API monitoring, and the EM CLI equivalents.
- [Monitoring Readiness](monitoring-readiness.md) — checks each feature against the settings live on the target, and applies the `auto_explain` settings where the plug-in can set them itself.

### Advisors

- [Plan Analysis](plan-analysis.md) — execution plans harvested from the server log, with per-node estimated-versus-actual rows and five detection rules run over each plan.
- [Plan Drift Advisor](plan-drift-advisor.md) — accepted-good baseline plans per query, drift detection against them on the page and as an alert, and the Fix Workbench.
- [Workload History](workload-history.md) — replays the `pg_stat_statements` snapshots in the agent-local store across a window you choose, so you can see which statements grew and by how much.
- [Index Advisor](index-advisor.md) — the indexes worth creating, dropping, or rebuilding on each database, each with SQL you review and run yourself.
- [Vacuum Advisor](vacuum-advisor.md) — why a table keeps growing: its storage parameters, autovacuum frequency, or whatever is pinning the transaction horizon.

### Reference

- [Monitoring pages](monitoring-pages.md) — a tour of Overview, Configuration, Realtime, Database, Tables, Indexes, Queries, Query Analyzer, License Info, and the cluster home page.
- [Alerts and templates](alerts-and-templates.md) — every advisor finding as a standard Enterprise Manager metric, its default thresholds, and three importable monitoring templates.
- [History store and retention](history-store-and-retention.md) — the per-target SQLite store on the agent host, the **Retention Policies** page, the size ceiling, and the daily prune.
- [Jobs and metric extensions](jobs-and-metric-extensions.md) — every job type the plug-in ships, and how to collect your own SQL query as a Metric Extension.
- [Troubleshooting](troubleshooting.md) — empty advisor pages, placeholder KPIs, and failed actions, listed by the exact message you see.
- [Changelog](changelog.md) — what changed in each release, most recent first.

## Support

If you need assistance with the PostgreSQL Plugin for Oracle Enterprise Manager:

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)
