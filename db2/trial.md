---
title: Trial setup
nav_order: 3
---

# Trial setup

To evaluate the IBM Db2 plug-in against your own Db2 databases, on your own OMS, you need a licence key for `ip.em.xdb2`. Request a key, enter it on each target, then work the guided checklist below. It touches every page and metric family the plug-in ships.

> **Prerequisites for this page**
> - Enterprise Manager 13.5 or 24ai, with an agent that can reach the Db2 databases you want to evaluate: see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).
> - Db2 LUW 11.5 or 12.1 and a least-privilege monitoring user on each database: see [The monitoring role](prerequisites.md#monitoring-role).
> - For the local-only jobs in the checklist, an agent on the same host as the Db2 instance: see [Network and ports](prerequisites.md#network).

**Where to find it:** the key is requested through the form at [integrationplumbers.io/db2-plugin/trial](https://integrationplumbers.io/db2-plugin/trial) or your Integration Plumbers contact. It goes in the target's **Plug-in Licence Key** credential, under **Target Setup → Monitoring Configuration**, and the target's **License Info** page confirms it.

**In this page:** Request a key · Your licence key · Install · Guided evaluation · Send us your findings · Coming from the Open Beta

## Request a key

Request the key before you install anything: a valid licence key is required to monitor a target, and you are asked for it while adding the target. Fill in the form at [integrationplumbers.io/db2-plugin/trial](https://integrationplumbers.io/db2-plugin/trial), or email your Integration Plumbers contact or **helpdesk@integrationplumbers.io**, with:

| What we ask for | Why it matters |
| :--- | :--- |
| Your Enterprise Manager line, 13.5 or 24ai | It decides which build you receive, `13.5.3.0.0` or `24.1.2.0.0`. Both carry the same features. |
| Your Db2 versions, 11.5 or 12.1 | Versions 11.1 and below are not supported: see [Supported versions and platforms](prerequisites.md#supported-versions). |
| How many databases you want to monitor | A key carries a licensed instance count, or `Unlimited`. A key with an instance count also needs the OMS settings described in [Licensing](targets-and-properties.md#oms-settings). |
| Whether the agent will be local or remote to each database | Metric collection, and the three remote administrative jobs, work either way. Local-only capabilities (the six local administrative jobs, Kill and diagnostic-log monitoring) need the agent on the same host as the database. See [Network and ports](prerequisites.md#network). |

While you wait, work through the [Prerequisites checklist](prerequisites.md#checklist) on the database you plan to evaluate: creating the monitoring user is the one step worth starting early, since it needs a DBA connection.

## Your licence key {#your-licence-key}

Trial keys are issued for 30 days (ask helpdesk to confirm the length, or to extend a trial). A trial key's type is `Trial` and its instance count is `Unlimited`, so it needs none of the OMS settings that a key with an instance count needs.

The key is issued for `ip.em.xdb2` specifically. A key issued for the Open Beta plug-in (`ip.em.xdbb`) does not work on GA, and the reverse is also true.

### Enter the key

1. Open the target and go to **Target Setup → Monitoring Configuration**.
2. Enter the key in the **Plug-in Licence Key** field of the licence credential set (*IBM DB2 Plug-in Licence Monitoring Credentials*), exactly as issued, as one line. Leave the **Plugin Licence Key (legacy - set the credential instead)** property empty: it is read only while the credential is empty, and only for targets upgraded from 24.1.1.0.0.
3. Save.
4. Repeat for every target. Keys are entered per target, so a second database added later needs the same key entered again. IBM Db2 Instance targets take the same key, in their own licence credential set, and do not count against its instance limit.

With EM CLI, set the key through the `DB2LicenseMonitoringCreds` credential set: see [Licensing](targets-and-properties.md#licensing).

### Verify it

Open the target's **License Info** page, or its **License** metric under **All Metrics**. It reports the status, the licence type, expiration, instance count, and days remaining.

| Status | Meaning |
| :--- | :--- |
| `Active` | The key is genuine, issued for `ip.em.xdb2`, and in date. |
| `License Required` | No key has been entered. |
| `Invalid Signature` | The key text was altered, or it was issued for a different plug-in identity. |
| `Grace Period` | The key expired less than 14 days ago. Collection continues, with a Warning. |
| `Expired` | The key expired 14 or more days ago. |
| `Exceeded Limit` | More `ip_db2_database` targets exist than the key's instance count. Only this plug-in's own targets count, never targets under a different Db2 plug-in. Collection keeps running, and the licence alert stays open. |

If the status is `License Required`, `Invalid Signature` or `Expired`, every metric group except **Response**, **License**, **Version**, **CollectorStatus** and **readiness_summary** reports a collection error until you fix it. See [Troubleshooting](troubleshooting.md#licence-gate).

## Install

Create the monitoring user, import the OPAR, deploy it to the OMS and to the agents, add a target, enter the key, and confirm the first collection. Follow [Getting started](getting-started.md): it walks the whole path in order.

## Guided evaluation {#guided-evaluation}

Work the rows in order and you will have touched every part of the plug-in.

### Day 1

Everything here needs only the target added and the key in place.

| What to do | What you should see | Page |
| :--- | :--- | :--- |
| Open the target's **Overview** page. | The Database and Monitoring and License cards, seven Key Indicators tiles, the Health Overview with one row per area and a link to the page behind each, the Connections and Lock & Deadlock Activity charts, open incidents and Related Targets. | [Monitoring pages](monitoring-pages.md#overview) |
| Open **Locks** and read **Blocking Chains**. | Who waits on whom, down to the root blocker, with **Kill** on a root blocker's row, which asks for confirmation before it submits the *Kill IBM Db2 Application* job. *Nothing is waiting on a lock right now* means a healthy, uncontended database, not a collection failure. | [Monitoring pages](monitoring-pages.md#locks) |
| Open **Performance** and pick **Last hour**. | Buffer pool I/O, cache hit ratios, transaction log I/O and SQL activity over the last hour. **Real time** starts empty and fills in, one point a minute. | [Monitoring pages](monitoring-pages.md#performance) |
| Open **Storage**. | Table space use, storage-path headroom, and the days-to-full forecast. The transaction log is on **Transaction Log**. | [Monitoring pages](monitoring-pages.md#storage) |
| Open **Backup**. | The last backup and the days since it, Db2's recovery history with failures highlighted, and any utilities running now. | [Monitoring pages](monitoring-pages.md#backup) |

### Day 2 to 3

These need a little more time.

| What to do | What you should see | Page |
| :--- | :--- | :--- |
| Open **SQL** and pick **Last day**. | The top statements by CPU time or by executions, with their SQL text. Read [Statement text and your data](whats-new.md#statement-text-privacy) first if the database holds sensitive values. | [Monitoring pages](monitoring-pages.md#sql) |
| If the database is in an HADR pair, open **High Availability**. | Takeover readiness and standby lag per standby, with log gap and replay lag over the window. | [HADR monitoring](hadr-monitoring.md) |
| Set the target's preferred credentials and run a remote **RUNSTATS on a Table** job against a test table. | The job completes and its output carries Db2's own message. | [Jobs](jobs-and-metric-extensions.md#remote-admin-jobs) |
| Open **Monitoring Readiness** and press **Check again**. | One panel per monitoring feature, with a status per item and, where something is missing, the statement that fixes it. Optional items such as deadlock capture read Attention until a DBA sets them up. | [Monitoring pages](monitoring-pages.md#monitoring-readiness) |
| Add an **IBM Db2 Instance** target for the instance that runs the database, with the same key. | Six instance pages: memory against its limit, agents, the instance's `db2diag.log` and its configuration. Once Enterprise Manager links the two (at the next configuration collection), the database's Overview names its instance. | [Instance targets](targets-and-properties.md#instance-targets) |
| On a test database with archive logging, open **Backup** and press **Back Up Database**, Now. | Db2's time stamp for the image and where it is; the backup appears in the Recovery History after the next collections. Needs the admin and agent-owner preferred credentials. | [Monitoring pages](monitoring-pages.md#backup) |
| Associate the three compliance standards with your target. | Association Count moves from 0 to 1 on each of the three standards. | [Compliance standards](compliance-standards.md#associate) |

### Week 1

| What to do | What you should see | Page |
| :--- | :--- | :--- |
| Let a configuration collection run (every 24 hours), then open **Compliance → Results**. | Scored results for all three standards: configuration best-practices, audit posture, and version lifecycle. A fresh, unhardened install typically shows some findings on the first two, because several rules check Db2's own defaults: that is real signal, not a broken check. | [Compliance standards](compliance-standards.md) |
| Review the curated default thresholds on **Metric and Collection Settings**. | Warning and Critical values already set on the metrics in [Alerts and thresholds](alerts-and-templates.md#default-thresholds), sized for a general estate rather than tuned to yours. | [Alerts and thresholds](alerts-and-templates.md) |
| Watch **Days to Full** in the Table Spaces table on Storage over several days. | Days to Full moves from **No forecast** (`DaysToFull` = `9999` under All Metrics) to a real projection once there is enough history to fit a trend. | [Monitoring pages](monitoring-pages.md#storage) |

## Send us your findings {#send-us-your-findings}

Tell us what you found, including the parts that did not work.

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)

Include the plug-in version (`emcli list_plugins_on_server`), your Enterprise Manager line, the Db2 version, the metric group or page involved, and any deploy log, agent log, or collection-error text.

Before you write, check [Troubleshooting](troubleshooting.md). An empty page, a job that fails on credentials, and a licence surprise each have a known cause and a fix there.

## Coming from the Open Beta

If you evaluated the Open Beta, GA is a different plug-in: install it fresh alongside the beta, re-create your targets with a GA key, then retire the beta. See [Moving from the beta to GA](beta-pre-release.md).

## Related

- [Getting started](getting-started.md): the install path this trial follows, step by step
- [Prerequisites](prerequisites.md#checklist): the checklist to work through while you wait for the key
- [Monitoring pages](monitoring-pages.md): every page exercised above, and the rest
- [Compliance standards](compliance-standards.md): associating standards, in the Week 1 step
- [Troubleshooting](troubleshooting.md): support contacts, and the common first-hour symptoms explained
