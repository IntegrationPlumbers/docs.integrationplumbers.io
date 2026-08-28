---
title: Install and upgrade
nav_order: 6
---

# Install and upgrade

> **Prerequisites for this page**
> - `emcli` available on the OMS host, logged in as a user that can import and deploy plug-ins.
> - The right artifact for your Enterprise Manager release. A 24ai OPAR is refused at import on a 13.5 OMS. See [Which build you need](#which-build).

**In this page:** Which build you need · Installing · Upgrading · Removing · What a plug-in deploy does not change

## Which build you need {#which-build}

The plug-in ships as two builds from the same source:

| Your Enterprise Manager | Build | Numbered |
| :--- | :--- | :--- |
| 24ai (24.1) | 24ai artifact | `24.1.x` |
| 13.5 | 13.5 artifact | `13.5.x` |

They are the same code with the same features. The difference is the Enterprise Manager toolkit each was built with, and that is what Enterprise Manager checks on import — not the version number. Importing the 24ai build on a 13.5 management server is refused outright, with a message about an incompatible version created for a higher release.

If you are unsure which you have, the version is on the Enterprise Manager console banner.

## Installing {#installing}

1. **Import the archive** into the Software Library:

   ```
   emcli login -username=sysman
   emcli import_update -file="/tmp/<the .opar file>" -omslocal
   ```

2. **Deploy to the management server.** This takes several minutes and runs its own prerequisite checks first:

   ```
   emcli deploy_plugin_on_server -plugin=<plug-in id> -sys_password=<repository password>
   ```

3. **Deploy to each agent** that will monitor SQL Server:

   ```
   emcli deploy_plugin_on_agent -plugin=<plug-in id> -agent_names="<agent host>:<port>"
   ```

Track either deploy with `emcli get_plugin_deployment_status -plugin=<plug-in id>`.

There is no separate driver step. The Microsoft JDBC driver is inside the plug-in's collection JAR.

Once the agent deploy finishes you can add targets — see [Targets and properties](targets-and-properties.md).

## Upgrading {#upgrading}

Import the newer archive and deploy it the same way. Existing targets, their credentials and any thresholds you have tuned are preserved.

This describes the general release. **During Early Access there is no supported in-place upgrade between beta drops** - see [Early access](early-access.md#not-verified). It is a fresh plug-in with no earlier build to upgrade from, so the upgrade path has not been exercised.

Two things worth knowing:

- **Enterprise Manager will not import a version it already has.** Re-importing the same version number is refused with a message that the entity already exists. If you are given a rebuilt archive at the same number, ask for one with the version incremented rather than trying to force it.
- **A newly deployed version does not re-collect history.** Existing collected data stays; new metrics introduced by the upgrade begin collecting on their own schedules.

## Removing {#removing}

Undeploy from the agents first, then from the management server:

```
emcli undeploy_plugin_from_agent -plugin=<plug-in id> -agent_names="<agent host>:<port>"
emcli undeploy_plugin_from_server -plugin=<plug-in id> -sys_password=<repository password>
```

Undeploying from an agent with `-delete_targets` removes the targets it was monitoring. Without it, the targets remain and go to an unmonitored state.

The archive also stays in the Software Library after undeploy. Remove it from the Self Update console if you want it gone entirely.

## What a plug-in deploy does not change {#no-change}

Deploying the plug-in touches Enterprise Manager, not your databases. It creates no objects on the monitored instance, runs no DDL, and changes no SQL Server configuration. Everything it reads, it reads through the monitoring login's read-only grants.

The only SQL Server-side writes this plug-in ever performs are the ones you explicitly ask for by running a job — a backup, a restore, an index creation — and those are covered in [Jobs](jobs.md).

## Related

- [Prerequisites](prerequisites.md#enterprise-manager) - supported Enterprise Manager and agent versions
- [Early access](early-access.md) - what the beta build is, and how it is numbered
- [Targets and properties](targets-and-properties.md) - the next step after deploying
- [Troubleshooting](troubleshooting.md#import-deploy) - import and deploy failures
- [Getting started](getting-started.md) - the whole path, of which this is one step
