---
title: Getting started
nav_order: 2
---

# Getting started

The shortest path from a downloaded archive to a Db2 target you can actually look at: five steps, each with what to do and how you know it worked, then links to the page that carries the detail. If you are reading this, you have agreed to try something before it is finished, and your time is the thing we are spending — so this page stays short on purpose.

> **Prerequisites for this page**
> - OMS access that can import an OPAR and deploy plug-ins, for example `sysman` — see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).
> - A Linux x86-64 or Windows x86-64 Management Agent with a network path to the Db2 server — see [Network and ports](prerequisites.md#network).
> - The ability to create a least-privilege monitoring user on the Db2 database — see [The monitoring role](prerequisites.md#monitoring-role).
> - Your **beta licence key** for `ip.em.xdbb`, from your Integration Plumbers contact. Request one from the [trial page](trial.md) if you do not have one yet.

**Where to find it:** install and deployment under Setup ▸ Extensibility ▸ Plug-ins; the target under Setup ▸ Add Target ▸ Add Targets Manually; everything the plug-in shows you afterwards under the target's own navigation tree.

**In this page:** The one thing worth knowing · Step 1: Create the monitoring user · Step 2: Install the plug-in · Step 3: Add your first target · Step 4: Enter the licence key · Step 5: Check the first collection · What to look at first · If something is wrong

## The one thing worth knowing before you start {#licence-key}

**A beta target comes Up without a licence key, then collects almost nothing.** That surprises people, because the target looks healthy in All Targets while every page except **License**, **Response**, and **Version** stays empty. This is deliberate: from `24.1.9.9.0` / `13.5.9.4.0`, an unlicensed target's other metric groups report a collection error reading `Collection stopped by license status: <status>` rather than silently going Down. Enter the key when you create the target and the question never arises — see [Step 4](#step-4-enter-the-licence-key) below, and [Troubleshooting](troubleshooting.md#licence-gate) if you meet it anyway.

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

Import the OPAR that matches your Enterprise Manager onto the OMS, deploy it there, then deploy it to every agent that will monitor a Db2 database, in that order.

```
emcli login -username=<em administrator>
emcli import_update -file=/tmp/<artifact>.opar -omslocal
emcli deploy_plugin_on_server -plugin=ip.em.xdbb:24.1.9.9.0
emcli get_plugin_deployment_status -plugin=ip.em.xdbb      # wait for Success
emcli deploy_plugin_on_agent -plugin=ip.em.xdbb:24.1.9.9.0 -agent_names="<agent_host>:<agent_port>"
```

Use `13.5.9.4.0` in place of `24.1.9.9.0` on Enterprise Manager 13.5. On 24ai, `deploy_plugin_on_server` takes `-dbUser`/`-dbPassword` for the repository account rather than `-sys_password`.

**Done when** `emcli get_plugin_deployment_status -plugin=ip.em.xdbb` reports the deployment complete for the OMS and for each agent, and **IBM DB2 Database (Beta)** appears in the Add Target list for that agent.

Detail: [Import the OPAR](install-and-upgrade.md#import) · [Deploy to the OMS](install-and-upgrade.md#deploy-oms) · [Deploy to agents](install-and-upgrade.md#deploy-agents).

## Step 3: Add your first target {#step-3}

Go to **Setup ▸ Add Target ▸ Add Targets Manually**, select the host running the agent you deployed to, choose the **IBM DB2 Database (Beta)** target type, and click **Add**. Fill in the database name, host, and port (defaults to `localhost` and `50000`), the `oem_monitor` monitoring credentials, and — while you are here — the licence key from Step 4.

**Done when** the target appears under All Targets and its status reads Up. Up means only that the agent reached Db2 and got a response; see Step 5 before you conclude monitoring itself is working.

Detail: [Add a target from the console](targets-and-properties.md#add-target-console) · [Instance properties and credentials](targets-and-properties.md#target-properties).

## Step 4: Enter the licence key {#step-4-enter-the-licence-key}

Enter your beta key in the target's **Plugin Licence Key** property, either on the properties screen while you add the target or afterwards under **Target Setup ▸ Monitoring Configuration**. The **License** metric then reports the licence state every 15 minutes, and again as soon as the property changes.

**Done when** the **License** metric reports `Active`. Anything else — `License Required`, `Invalid Signature`, `Expired`, `Exceeded Limit` — stops ordinary collection on that target; see [Troubleshooting](troubleshooting.md#licence-gate) for what each status means and how to fix it.

Detail: [Instance properties and credentials](targets-and-properties.md#target-properties) · [Troubleshooting](troubleshooting.md#licence-gate).

## Step 5: Check the first collection {#step-5}

Within a few minutes the target should show **Up**, its Home page should fill in, and the **License** metric should report `Active`. These are three separate signals and they fail independently:

- **Up** means the agent reached Db2 and got a response. If it stays Down, the problem is connectivity or credentials.
- **`License` = `Active`** means the key was accepted. Anything else stops ordinary collection — see [Troubleshooting](troubleshooting.md#licence-gate).
- **A populated Home page** means collections are running and uploading.

A target that is Up with an empty Home page is almost always the licence key.

## What to look at first

Open the target's **Home** page first — availability, a configuration summary, connections, lock and deadlock activity, HADR status if the database is in an HADR pair, and open incidents, all in one place. From there:

1. **Analysis** — live lock contention, and the applications waiting longest with a **Kill Application** action.
2. **Performance** — buffer pool I/O, cache hit ratios, transaction-log I/O, and space utilization.
3. **All Metrics** — backup/restore/load history, top-SQL trends, and the full HADR column set live here as metric groups rather than as dedicated page regions in this release.

Every page is described in [Monitoring pages](monitoring-pages.md).

## If something is wrong

Start with [Troubleshooting](troubleshooting.md) — it opens with the licence-gate symptoms, which account for most of what people hit in the first hour.

If the answer is not there, send it to your Integration Plumbers support contact with the plug-in version (`emcli list_plugins_on_server`), your Enterprise Manager line, the Db2 version, the metric group or page involved, and any deploy log, agent log, or collection-error text.

## Related

- [Trial setup](trial.md) — the guided evaluation checklist that follows this page
- [Prerequisites](prerequisites.md) — the full requirements behind every step here
- [Install and upgrade](install-and-upgrade.md#import) — import and deploy in more detail, and the same sequence for an upgrade
- [Targets and properties](targets-and-properties.md) — every target property, and adding targets with EM CLI
- [Troubleshooting](troubleshooting.md#licence-gate) — the licence-gate symptoms most people hit first
