---
title: Getting started
nav_order: 2
---

# Getting started

The shortest path from a downloaded archive to a Db2 target you can actually look at: five steps, each with what to do and how you know it worked, then links to the page that carries the detail.

> **Prerequisites for this page**
> - OMS access that can import an OPAR and deploy plug-ins, for example `sysman` — see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).
> - A Linux x86-64 or Windows x86-64 Management Agent with a network path to the Db2 server — see [Network and ports](prerequisites.md#network).
> - The ability to create a least-privilege monitoring user on the Db2 database — see [The monitoring role](prerequisites.md#monitoring-role).
> - Your **licence key** for `ip.em.xdb2`, from Integration Plumbers. Request one from the [trial page](trial.md) if you do not have one yet.

**Where to find it:** install and deployment under Setup ▸ Extensibility ▸ Plug-ins; the target under Setup ▸ Add Target ▸ Add Targets Manually; everything the plug-in shows you afterwards under the target's own navigation tree.

**Coming from the Open Beta?** GA is a different plug-in, installed fresh alongside the beta — read [Moving from the beta to GA](beta-pre-release.md) first.

**In this page:** The one thing worth knowing · Step 1: Create the monitoring user · Step 2: Install the plug-in · Step 3: Add your first target · Step 4: Enter the licence key · Step 5: Check the first collection · What to look at first · If something is wrong

## The one thing worth knowing before you start {#licence-key}

**A target comes Up without a licence key, then collects almost nothing.** That surprises people, because the target looks healthy in All Targets while every metric group except **Response**, **License**, **Version** and **CollectorStatus** stays empty. This is deliberate: an unlicensed target's other metric groups report a collection error beginning `Collection stopped by license status` rather than silently going Down, so a missing key never makes a database look down. Enter the key when you create the target and the question never arises — see [Step 4](#step-4-enter-the-licence-key) below, and [Troubleshooting](troubleshooting.md#licence-gate) if you meet it anyway.

## Step 1: Create the monitoring user {#step-1}

The plug-in connects over JDBC as a dedicated, low-privilege user — never `SYSADM`, `DBADM`, or `DATAACCESS`. Db2 LUW authenticates externally, so create the OS user first (example: `oem_monitor`), then grant it database authorities:

```sql
-- Connect as an instance/DB administrator to the monitored database:
--   db2 connect to <DBNAME>

GRANT CONNECT ON DATABASE TO USER oem_monitor;
GRANT SQLADM ON DATABASE TO USER oem_monitor;
```

`SQLADM` is the one grant that covers the entire metric surface: every `MON_GET_*` monitoring table function the plug-in calls, and `SELECT` on the recovery-history and audit-posture catalog views the backup-history and compliance content read. It is genuinely required, not a convenience — see [The monitoring role](prerequisites.md#monitoring-role) for what fails without it.

**Done when** `oem_monitor` can connect to the database from the agent host: `db2 connect to <DBNAME> user oem_monitor using <password>`.

Detail: [The monitoring role](prerequisites.md#monitoring-role) · [Optional transport security](prerequisites.md#tls).

## Step 2: Install the plug-in {#step-2}

Import the OPAR that matches your Enterprise Manager onto the OMS, deploy it there, then deploy it to every agent that will monitor a Db2 database, in that order. Verify the file's SHA-256 checksum first — see [Download](install-and-upgrade.md#download).

```
emcli login -username=<em administrator>
emcli import_update -file="/tmp/24.1.1.0.0_ip.em.xdb2_2000_0.opar" -omslocal
emcli deploy_plugin_on_server -plugin="ip.em.xdb2:24.1.1.0.0" -dbUser=SYS -dbPassword=<repository SYS password>
emcli get_plugin_deployment_status -plugin=ip.em.xdb2      # wait for Success
emcli deploy_plugin_on_agent -plugin="ip.em.xdb2:24.1.1.0.0" -agent_names="<agent_host>:<agent_port>"
```

On Enterprise Manager 13.5, use `13.5.2.0.0_ip.em.xdb2_2000_0.opar` and `13.5.2.0.0` in place of `24.1.1.0.0`, and pass `-sys_password=<repository SYS password>` in place of `-dbUser`/`-dbPassword` (Enterprise Manager 13.5 accepts either form; 24ai accepts only `-dbUser`/`-dbPassword`). Always pin the `:version` on both deploy commands.

**Done when** `emcli get_plugin_deployment_status -plugin=ip.em.xdb2` reports the deployment complete for the OMS and for each agent, and **IBM DB2 Database** appears in the Add Target list for that agent.

Detail: [Import the OPAR](install-and-upgrade.md#import) · [Deploy to the OMS](install-and-upgrade.md#deploy-oms) · [Deploy to agents](install-and-upgrade.md#deploy-agents).

## Step 3: Add your first target {#step-3}

Go to **Setup ▸ Add Target ▸ Add Targets Manually**, choose **Add Target Declaratively**, select the **IBM DB2 Database** target type and the agent you deployed to. Fill in the database name, host, and port (defaults to `localhost` and `50000`), the `oem_monitor` monitoring credentials, and — while you are here — the licence key from Step 4. Click **Test Connection**, then save.

**Done when** the target appears under All Targets and its status reads Up. Up means only that the agent reached Db2 and got a response; see Step 5 before you conclude monitoring itself is working.

Detail: [Add a target from the console](targets-and-properties.md#add-target-console) · [Instance properties and credentials](targets-and-properties.md#target-properties) · [Add a target with EM CLI](targets-and-properties.md#add-target-emcli).

## Step 4: Enter the licence key {#step-4-enter-the-licence-key}

Enter your key in the target's **Plugin Licence Key** property, either on the properties screen while you add the target or afterwards under **Target Setup ▸ Monitoring Configuration**. Paste it exactly as issued, as one line. The **License** metric then reports the licence state every 15 minutes, and again as soon as the property changes.

**Done when** the **License** metric reports `Active`. `License Required`, `Invalid Signature` or `Expired` stops ordinary collection on that target; `Exceeded Limit` keeps it running but leaves the licence alert open. See [Licensing](targets-and-properties.md#licensing) for each status, and for the OMS settings a key with an instance limit needs.

Detail: [Licensing](targets-and-properties.md#licensing) · [Troubleshooting](troubleshooting.md#licence-gate).

## Step 5: Check the first collection {#step-5}

Within a few minutes the target should show **Up**, its Home page should fill in, and the **License** metric should report `Active`. These are three separate signals and they fail independently:

- **Up** means the agent reached Db2 and got a response. If it stays Down, the host or port is unreachable or the instance is stopped. A wrong password, a missing grant or a TLS problem shows as a *metric collection error* on the target instead, naming what to fix.
- **`License` = `Active`** means the key was accepted. See [Troubleshooting](troubleshooting.md#licence-gate) for anything else.
- **A populated Home page** means collections are running and uploading. Groups collect on intervals from 5 minutes to 24 hours, so some sections fill in later than others.

A target that is Up with an empty Home page is almost always the licence key. For any other empty metric group, read the target's **CollectorStatus** metric: it says, per group, whether it is collecting, not configured, not collected yet, gated off, or failing — see [Troubleshooting](troubleshooting.md#empty-group).

## What to look at first

Open the target's **Home** page first. Its **Health Overview** gives one row per area — availability, storage, transaction log, backup and recovery, HADR, locks, performance, SQL workload, licence, and diagnostics — with Enterprise Manager's own verdict and a link to the page that explains it. From there:

1. **Storage** and **Backup History** — table space use and forecast, the transaction log, file-system headroom, and the last backup.
2. **Analysis** — live lock contention, with a **Kill Blocking Application** action on the applications holding the locks.
3. **Performance** and **SQL Analytics** — buffer pool, cache and I/O detail, and the top statements with their SQL text.
4. **HADR** — takeover readiness and standby lag, when the database is in an HADR pair.

Every page is described in [Monitoring pages](monitoring-pages.md).

## If something is wrong

Start with [Troubleshooting](troubleshooting.md) — it opens with the licence-gate symptoms, which account for most of what people hit in the first hour.

If the answer is not there, send it to **helpdesk@integrationplumbers.io** with the plug-in version (`emcli list_plugins_on_server`), your Enterprise Manager line, the Db2 version, the metric group or page involved, and any deploy log, agent log, or collection-error text.

## Related

- [Trial setup](trial.md) — the guided evaluation checklist that follows this page
- [Prerequisites](prerequisites.md) — the full requirements behind every step here
- [Install and upgrade](install-and-upgrade.md#import) — import and deploy in more detail, and the same sequence for an upgrade
- [Targets and properties](targets-and-properties.md) — every target property, adding targets with EM CLI, and licensing
- [Troubleshooting](troubleshooting.md#licence-gate) — the licence-gate symptoms most people hit first
