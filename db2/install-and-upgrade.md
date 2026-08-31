---
title: Install and upgrade
nav_order: 5
---

# Install and upgrade

Installing the IBM DB2 plug-in follows Oracle Enterprise Manager's standard plug-in lifecycle: import the OPAR onto the OMS, deploy it to the OMS and to each monitoring agent, then licence and add your targets. Moving between beta drops follows the same import-and-deploy sequence, but because metadata can change between drops, replacing a build within the beta line is an undeploy-then-redeploy rather than a silent in-place update — see [Upgrade from an earlier drop](#upgrade) below.

> **Prerequisites for this page**
> - Your Enterprise Manager and Db2 versions are supported — see [Supported versions and platforms](prerequisites.md#supported-versions).
> - You have OMS access to import the OPAR and an account (for example `sysman`) with plug-in deployment privileges for `emcli` — see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).

**Where to find it:** Setup → Extensibility → Plug-ins → Databases → IBM DB2 Database (Beta) → Actions → Deploy On, or the equivalent `emcli` plug-in commands shown below.

**In this page:** Licence key · Download · Import the OPAR · Deploy to the OMS · Deploy to agents · Upgrade from an earlier drop · After an upgrade · Uninstall

## Licence key

A valid beta licence key is required to monitor a target. Request one through your Integration Plumbers contact — see [Trial setup](trial.md).

You enter the key per target, in the **Plugin Licence Key** target property (see [Targets and properties](targets-and-properties.md#target-properties)). To confirm a target's key is recognized, check its **License** metric under All Metrics.

## Download {#download}

Download details for the plug-in OPAR, including its SHA-256 checksum, come with your beta enrollment. The plug-in ships as two builds with the same features: **24.1.9.8.0** for Enterprise Manager 24ai and **13.5.9.3.0** for Enterprise Manager 13.5. Download the one that matches your Enterprise Manager — the other is refused at import with `Incompatible version`, because each is built with that Enterprise Manager line's own development kit. Verify the checksum before you import it.

## Import the OPAR {#import}

1. Log in to `emcli` and enter the password when prompted:

   ```
   emcli login -username=sysman
   ```

2. Import the OPAR file:

   ```
   emcli import_update -file="/tmp/24.1.9.8.0_ip.em.xdbb_2000_0.opar" -omslocal
   ```

   (Use `-omslocal` when the file is on the OMS host; use `-host`/`-credential_set_name` when importing from an agent host.) The plug-in then appears under **Setup → Extensibility → Plug-ins**, in the **Databases** category, as **IBM DB2 Database (Beta)**.

## Deploy to the OMS {#deploy-oms}

1. Navigate to **Setup → Extensibility → Plug-ins**.
2. Expand the Databases folder and click **IBM DB2 Database (Beta)**.
3. From the Actions menu, click **Deploy On → Management Servers** and follow the on-screen instructions.

The equivalent `emcli` command:

```
emcli deploy_plugin_on_server -plugin=ip.em.xdbb:24.1.9.8.0 -dbUser=SYS -dbPassword=<repository_SYS_password>
```

On Enterprise Manager 24ai, `deploy_plugin_on_server` takes `-dbUser`/`-dbPassword` for the repository account — **not** `-sys_password`, which is rejected. Always pin the `:version`, on this command and on the agent deploy below, or an upgrade is silently skipped as "already deployed".

To check deployment progress from either the console or `emcli`, run:

```
emcli get_plugin_deployment_status -plugin=ip.em.xdbb
```

Each deploy is asynchronous, and a drop that moves target metadata restarts the OMS as part of this step — wait for the status command to report **Success**, and for the server to actually report the version, before continuing.

## Deploy to agents {#deploy-agents}

1. From the same Plug-ins page, select **IBM DB2 Database (Beta)**.
2. From the Actions menu, click **Deploy On → Management Agents**.
3. Follow the on-screen instructions to select the agent hosts.

The equivalent `emcli` command:

```
emcli deploy_plugin_on_agent -plugin=ip.em.xdbb:24.1.9.8.0 -agent_names="<host>:<port>"
```

`get_plugin_deployment_status` (shown above) reports agent deployment progress just as it does for the OMS. Deploy the agent side in the same maintenance window as the OMS side: until you do, metrics added by a metadata-bumping drop have nowhere to come from, and their pages stay empty while everything else keeps working.

## Upgrade from an earlier drop {#upgrade}

Because metadata may change between beta drops, replacing a build within the beta line is an undeploy-then-redeploy, not an in-place update:

```
emcli undeploy_plugin_from_agent  -plugin=ip.em.xdbb -agent_names="<agent_host>:<agent_port>" -delete_targets
emcli undeploy_plugin_from_server -plugin=ip.em.xdbb -dbUser=SYS -dbPassword=<repository_SYS_password>
```

Then **manually delete the old plug-in entry from Self Update** — Enterprise Manager does not remove it automatically — before importing the next drop's OPAR ([Import the OPAR](#import)) and deploying it ([Deploy to the OMS](#deploy-oms), [Deploy to agents](#deploy-agents)). `-delete_targets` removes the beta targets on that agent along with the plug-in; add new ones after the redeploy completes.

Beta-to-beta is the only in-place path this release supports. **Beta to GA is always a clean install, never a migration** — see [What's new](whats-new.md#beta-identity).

## After an upgrade {#after-upgrade}

Run, or schedule, the **Purge Stale Plugin Cache** job once per agent after every upgrade. It is housekeeping, not a fix: several metrics are deltas that keep a small cache file per target inside the versioned plug-in home, and an upgrade creates a new home, stranding the previous version's cache files. Skipping it wastes a small amount of disk and nothing else — it is safe to run at any time, and touches nothing in the current, live plug-in home. See [Jobs](jobs-and-metric-extensions.md#purge-stale-cache) for the full job detail, the credential it needs, and a scheduling example.

If a limited-instance licence key's instance count fails to validate right after an upgrade, see [Troubleshooting](troubleshooting.md#oms-licence-count) — it is a TLS-certificate issue on the licence-count connection, not a licence problem.

## Uninstall

1. Remove every IBM DB2 Database (Beta) target monitored by the plug-in.
2. Undeploy the plug-in from each agent:

   ```
   emcli undeploy_plugin_from_agent -plugin=ip.em.xdbb -agent_names="<host>:<port>"
   ```

3. Undeploy the plug-in from the OMS:

   ```
   emcli undeploy_plugin_from_server -plugin=ip.em.xdbb -dbUser=SYS -dbPassword=<repository_SYS_password>
   ```

4. Manually delete the plug-in entry from Self Update.

Undeploying the plug-in removes its versioned plug-in homes on the agent wholesale, including any stranded cache files — there is nothing further to clean up by hand.

## Related

- [Prerequisites](prerequisites.md) — confirm supported versions, network access, and the monitoring role before you deploy.
- [Targets and properties](targets-and-properties.md) — add a target and set its **Plugin Licence Key** property.
- [Jobs](jobs-and-metric-extensions.md#purge-stale-cache) — the job to run after every upgrade, in full.
- [Troubleshooting](troubleshooting.md) — fixes for deploy failures, licence-count errors, and other issues after an upgrade.
