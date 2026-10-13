---
title: Install and upgrade
nav_order: 5
---

# Install and upgrade

Installing the IBM Db2 plug-in follows Oracle Enterprise Manager's standard plug-in lifecycle: import the OPAR onto the OMS, deploy it to the OMS and to each monitoring agent, then add and licence your targets. This is the first general-availability release, so it is always a fresh install; GA updates after it upgrade in place with the same sequence — see [Upgrade](#upgrade) below.

> **Prerequisites for this page**
> - Your Enterprise Manager and Db2 versions are supported — see [Supported versions and platforms](prerequisites.md#supported-versions).
> - You have OMS access to import the OPAR and an account (for example `sysman`) with plug-in deployment privileges for `emcli` — see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).

**Where to find it:** Setup → Extensibility → Plug-ins → Databases → IBM DB2 Database → Actions → Deploy On, or the equivalent `emcli` plug-in commands shown below.

**In this page:** Licence key · Download · Import the OPAR · Deploy to the OMS · Deploy to agents · Upgrade · After an upgrade · Uninstall

## Licence key

A valid licence key for `ip.em.xdb2` is required to monitor a target. Request one through your Integration Plumbers contact — see [Trial setup](trial.md). A key issued for the Open Beta plug-in (`ip.em.xdbb`) does not work on GA.

You enter the key per target, in the **Plugin Licence Key** target property. To confirm a target's key is recognized, check its **License** metric under All Metrics. See [Licensing](targets-and-properties.md#licensing).

## Download {#download}

The plug-in ships as one OPAR per Enterprise Manager release, with the same features in each. Your Integration Plumbers contact provides the download. Use the one that matches your OMS: Enterprise Manager refuses to import an OPAR built for the other release (`Incompatible version`), because each is built with that Enterprise Manager line's own development kit.

| Enterprise Manager | OPAR | Plug-in version | SHA-256 |
| :--- | :--- | :--- | :--- |
| 24ai | `24.1.1.0.0_ip.em.xdb2_2000_0.opar` | `24.1.1.0.0` | `afa4e2fbb38651f6cd3b699e9fd5551f51e39fa56839dff7f300281faa08aa35` |
| 13.5 | `13.5.2.0.0_ip.em.xdb2_2000_0.opar` | `13.5.2.0.0` | `2cb83675ff82e21fd83b19c4f2294f1b8f7fd8747eefca15dd4afeb94568c7e9` |

The two lines are versioned independently. Verify the checksum before you import the file, for example `sha256sum 24.1.1.0.0_ip.em.xdb2_2000_0.opar` on Linux.

The commands below use the 24ai version. On Enterprise Manager 13.5, substitute `13.5.2.0.0` everywhere.

## Import the OPAR {#import}

1. Copy the OPAR to the OMS host, then log in to `emcli` and enter the password when prompted:

   ```
   emcli login -username=sysman
   ```

2. Import the OPAR file:

   ```
   emcli import_update -file="/tmp/24.1.1.0.0_ip.em.xdb2_2000_0.opar" -omslocal
   ```

   (`-omslocal` is for a file on the OMS host; use `-host` and `-credential_set_name` to import from an agent host instead.) The plug-in then appears under **Setup → Extensibility → Plug-ins**, in the **Databases** category, as **IBM DB2 Database**.

## Deploy to the OMS {#deploy-oms}

1. Navigate to **Setup → Extensibility → Plug-ins**.
2. Expand the Databases folder and click **IBM DB2 Database**.
3. From the Actions menu, click **Deploy On → Management Servers** and follow the on-screen instructions.

The equivalent `emcli` command, pinned to the version you imported:

```
emcli deploy_plugin_on_server -plugin="ip.em.xdb2:24.1.1.0.0" -dbUser=SYS -dbPassword=<repository_SYS_password>
```

`-dbUser` / `-dbPassword` are the Management Repository database's `SYS` account. Enterprise Manager 24ai rejects the older `-sys_password` form. On Enterprise Manager 13.5, use `13.5.2.0.0` in place of `24.1.1.0.0` and pass `-sys_password=<repository_SYS_password>` instead (13.5 also accepts `-dbUser`/`-dbPassword`). Always pin the `:version`, on this command and on the agent deploy below.

To check deployment progress, run:

```
emcli get_plugin_deployment_status -plugin=ip.em.xdb2
```

Each deploy is asynchronous, and the OMS may restart during it — wait for the status command to report **Success** before continuing.

## Deploy to agents {#deploy-agents}

1. From the same Plug-ins page, select **IBM DB2 Database**.
2. From the Actions menu, click **Deploy On → Management Agent**.
3. Follow the on-screen instructions to select the agent hosts.

The equivalent `emcli` command:

```
emcli deploy_plugin_on_agent -plugin="ip.em.xdb2:24.1.1.0.0" -agent_names="<host>:<port>"
```

Use `13.5.2.0.0` in place of `24.1.1.0.0` when deploying on Enterprise Manager 13.5. **Always pin the version**: without it, an agent that already has an earlier version of the plug-in can be reported as "already deployed" and skipped. Separate several agents with commas in `-agent_names`.

`get_plugin_deployment_status` (shown above) reports agent deployment progress just as it does for the OMS. Once the plug-in is on the OMS and at least one agent, you can add Db2 targets — see [Targets and properties](targets-and-properties.md).

## Upgrade {#upgrade}

**24.1.1.0.0 / 13.5.2.0.0 is the first GA release**, so there is no earlier GA version to upgrade from. GA updates after it upgrade in place: import the new release's OPAR and deploy it the same way as the first install, over the existing plug-in, pinning the new `:version` on both the server and the agent commands. Targets, their credentials and their collected history are kept. Deploy the agent side in the same maintenance window as the OMS side; until you do, metrics a release adds have nowhere to come from, and their pages stay empty while everything else keeps working.

**Coming from the Open Beta?** The beta (`ip.em.xdbb`) and GA (`ip.em.xdb2`) are different plug-ins, so beta to GA is always a clean install side by side, never an in-place upgrade. Follow [Moving from the beta to GA](beta-pre-release.md).

## After an upgrade {#after-upgrade}

Run, or schedule, the **Purge Stale Plugin Cache** job once per agent after every upgrade. It is housekeeping, not a fix: several metrics are deltas that keep a small cache file per target inside the versioned plug-in home, and an upgrade creates a new home, stranding the previous version's cache files. Skipping it wastes a small amount of disk and nothing else — it is safe to run at any time, and touches nothing in the current, live plug-in home. See [Jobs](jobs-and-metric-extensions.md#purge-stale-cache) for the full job detail, the credential it needs, and a scheduling example.

If a limited-instance licence key's instance count fails to validate, see [Troubleshooting](troubleshooting.md#oms-licence-count) — it is usually the OMS settings or the OMS certificate on the licence-count connection, not a licence problem.

**After an in-place Db2 upgrade** (for example 11.5 to 12.1), the detected Db2 version refreshes when the agent restarts or the plug-in is redeployed. To refresh it straight away, run this on the agent host:

```
emctl reload agent dynamicproperties <target name>:ip_db2_database
```

## Uninstall {#uninstall}

1. Remove every IBM DB2 Database target monitored by the plug-in.
2. Undeploy the plug-in from each agent:

   ```
   emcli undeploy_plugin_from_agent -plugin=ip.em.xdb2 -agent_names="<host>:<port>"
   ```

3. Undeploy the plug-in from the OMS:

   ```
   emcli undeploy_plugin_from_server -plugin=ip.em.xdb2 -dbUser=SYS -dbPassword=<repository_SYS_password>
   ```

   Use `-sys_password=<repository_SYS_password>` in place of `-dbUser`/`-dbPassword` on Enterprise Manager 13.5.

4. Manually delete the plug-in entry from Self Update.

Undeploying the plug-in removes its versioned plug-in homes on the agent wholesale, including any stranded cache files — there is nothing further to clean up by hand.

## Related

- [Prerequisites](prerequisites.md) — confirm supported versions, network access, and the monitoring role before you deploy.
- [Targets and properties](targets-and-properties.md) — add a target and set its **Plugin Licence Key** property.
- [Moving from the beta to GA](beta-pre-release.md) — for Open Beta users.
- [Jobs](jobs-and-metric-extensions.md#purge-stale-cache) — the job to run after every upgrade, in full.
- [Troubleshooting](troubleshooting.md) — fixes for deploy failures, licence-count errors, and other issues after an upgrade.
