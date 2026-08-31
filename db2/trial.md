---
title: Trial setup
nav_order: 3
---

# Trial setup

The Open Beta *is* the trial: a beta licence key gives you the whole product against your own Db2 databases, running on your own OMS. Request a key, enter it on each target, then work the guided checklist below. It touches every page and metric family the plug-in ships.

> **Prerequisites for this page**
> - Enterprise Manager 13.5 or 24ai, with an agent that can reach the Db2 databases you want to evaluate — see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).
> - Db2 LUW 11.5 or 12.1 and a least-privilege monitoring user on each instance — see [The monitoring role](prerequisites.md#monitoring-role).
> - For the local-only jobs section of the checklist, an agent co-located on the same host as the Db2 instance — see [Network and ports](prerequisites.md#network).

**Where to find it:** the key is requested through your Integration Plumbers contact. It goes in the target's **Plugin Licence Key** property, under **Target Setup ▸ Monitoring Configuration**, and the target's **License** metric confirms it.

**In this page:** Request a key · Your beta key · Install · Guided evaluation · Send us your findings · After the beta

## Request a key

Request the key before you install anything — a valid licence key is required to monitor a target, and it is a target property you will be asked for while adding the target. Email your Integration Plumbers contact, or the beta feedback contact supplied with your download, with:

| What we ask for | Why it matters |
| :--- | :--- |
| Your Enterprise Manager line, 13.5 or 24ai | It decides which artifact you receive, `13.5.9.3.0` or `24.1.9.8.0`. Both carry the same features. |
| Your Db2 versions, 11.5 or 12.1 | Versions below 11.5 are not supported — see [Supported versions and platforms](prerequisites.md#supported-versions). |
| How many databases you want to monitor | The key carries an instance count for limited keys; the beta programme's keys are typically `Trial` or `Unlimited`. |
| Whether the agent will be local or remote to each database | Metric collection works either way. Local-only capabilities — the five administrative jobs and diagnostic-log monitoring — need the agent on the same host as the database. See [Network and ports](prerequisites.md#network). |

While you wait, work through the [Prerequisites checklist](prerequisites.md#checklist) on the database you plan to evaluate: creating the monitoring user is the one step worth starting early, since it needs a DBA connection.

## Your beta key

Beta licence keys expire `2026-10-31`. Request one through your Integration Plumbers contact; it is minted for `ip.em.xdbb` specifically, so a GA key (once GA exists) will not work on the beta build, and a beta key will not work once you move to GA — see [What's new](whats-new.md#beta-identity).

### Enter the key

1. Open the target and go to **Target Setup ▸ Monitoring Configuration**.
2. Enter the key in the **Plugin Licence Key** property.
3. Save the properties.
4. Repeat for every target. Keys are entered per target, so a second database added later needs the same key entered again.

### Verify it

Open the target's **License** metric, under **All Metrics**. It reports the status, the licence type, expiration, instance count, and days remaining.

| Status | Meaning |
| :--- | :--- |
| `Active` | The key is genuine, issued for `ip.em.xdbb`, and in date. |
| `License Required` | No key has been entered. |
| `Invalid Signature` | The key text was altered, or it was issued for a different plug-in identity. |
| `Expired` | The key's expiry date has passed. |
| `Exceeded Limit` | More `ip_db2_database_beta` targets exist than the key's instance count. Only this plug-in's own targets count, never targets under a different Db2 plug-in. |

If the status is anything but `Active`, every metric group except **License**, **Response**, and **Version** reports a collection error until you fix it. See [Troubleshooting](troubleshooting.md#licence-gate).

## Install

Installing for the beta is the same work either way: create the monitoring user, import the OPAR, deploy it to the OMS and to the agents, add a target, enter the key, and confirm the first collection. Follow [Getting started](getting-started.md) — it walks the whole path in order.

## Guided evaluation

Work the rows in order and you will have touched every part of the plug-in.

### Day 1

Everything here needs only the target added and the key in place.

| What to do | What you should see | Page |
| :--- | :--- | :--- |
| Open the target's **Home** page. | Availability, a configuration summary, the Connections and Lock & Deadlock Activity charts, and open incidents. An HADR Status table appears too, empty unless the database is in an HADR pair. | [Monitoring pages](monitoring-pages.md#home) |
| Open **Analysis** and read **Top Waits by Blocked Application**. | The applications waiting longest on locks, each row selectable with a **Kill Application** button that submits the *Kill DB2 Application* job. An empty table is a healthy, uncontended database — not a collection failure. | [Monitoring pages](monitoring-pages.md#analysis) |
| Open **Performance** and read **Buffer Pool I/O** and **Cache Hit Ratios**. | A per-buffer-pool table of hit ratio and read counts, and a line chart of catalog- and package-cache hit ratios. | [Monitoring pages](monitoring-pages.md#performance) |
| Open **All Metrics** and find `Tablespace_Forecast`. | Per-tablespace `DaysToFull`, `PctUsed`, and growth rate. A fresh target may read `9999` (no forecast) until enough daily snapshots exist to fit a trend. | [Monitoring pages](monitoring-pages.md) |
| Open **All Metrics** and find `DB_History`. | One row per backup, restore, or load operation from `SYSIBMADM.DB_HISTORY`, with `operation_failed` set on any that failed. | [Monitoring pages](monitoring-pages.md) |

### Day 2 to 3

These need a little more time.

| What to do | What you should see | Page |
| :--- | :--- | :--- |
| Open **All Metrics** and find `Top_Queries_Cpu_Time` and `Top_Queries_Execution_Count`. | Statements keyed by a statement-ID hash, with CPU time and execution count and their per-hour rates. Numeric-only in this release — see [What's new](whats-new.md#known-limitations). | [Monitoring pages](monitoring-pages.md) |
| If the database is in an HADR pair, open **All Metrics** and find `HADR_Status` and `HADR_Readiness`. | Role, state, sync mode, connect status, heartbeat, log positions, and a `TakeoverReady` composite. | [HADR monitoring](hadr-monitoring.md) |
| From the agent monitoring the target, run **Purge Stale Plugin Cache** once from **Enterprise ▸ Job ▸ Activity ▸ Create Job**. | The job completes with no error even on a brand-new install — there is nothing stale to delete yet, which is the expected result. | [Jobs](jobs-and-metric-extensions.md#purge-stale-cache) |
| Associate the three compliance standards with your target. | Association Count moves from 0 to 1 on each of the three standards. | [Compliance standards](compliance-standards.md#associate) |

### Week 1

| What to do | What you should see | Page |
| :--- | :--- | :--- |
| Let a configuration collection run (every 24 hours), then open **Compliance ▸ Results**. | Scored results for all three standards: configuration best-practices, audit posture, and version lifecycle. A fresh, unhardened install typically shows some findings on the first two — that is real signal, not a broken check. | [Compliance standards](compliance-standards.md) |
| Review the curated default thresholds on **Metric and Collection Settings**. | Warning/Critical values already set on the metrics in [Alerts and thresholds](alerts-and-templates.md#default-thresholds), sized for a general estate rather than tuned to yours. | [Alerts and thresholds](alerts-and-templates.md) |
| Watch `Tablespace_Forecast` accumulate a second and third daily snapshot. | `GrowthBytesPerDay` and `DaysToFull` move from `9999`/no-forecast to a real projection once there is enough history to fit a trend. | [Monitoring pages](monitoring-pages.md) |

## Send us your findings

Tell us what you found, including the parts that did not work.

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)

Include the plug-in version (`emcli list_plugins_on_server`), your Enterprise Manager line, the Db2 version, the metric group or page involved, and any deploy log, agent log, or collection-error text. HADR-pair, Db2 11.5, and RDS observations fill known gaps in our own lab coverage and are especially valuable — see [What's new](whats-new.md#beta-status).

Before you write, check [Troubleshooting](troubleshooting.md). An empty page, a job that fails on credentials, and a licence surprise each have a known cause and a fix there.

## After the beta

Beta to GA is always a clean install, never an in-place upgrade — see [What's new](whats-new.md#beta-identity). When GA is available, plan it as a fresh deployment of `ip.em.xdb2` alongside the beta, verify parity per database the same way you would migrating from any other Db2 monitoring tool, then retire the beta targets.

## Related

- [Getting started](getting-started.md) — the install path this trial follows, step by step
- [Prerequisites](prerequisites.md#checklist) — the checklist to work through while you wait for the key
- [Monitoring pages](monitoring-pages.md) — the Home, Analysis, and Performance pages exercised above
- [Compliance standards](compliance-standards.md) — associating standards, in the Week 1 step
- [Troubleshooting](troubleshooting.md) — support contacts, and the common first-hour symptoms explained
