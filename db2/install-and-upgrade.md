---
title: Install and upgrade
nav_order: 5
---

# Install and upgrade

This page takes an Enterprise Manager administrator through installing the IBM Db2 plug-in, upgrading it in place from GA, and removing it. It follows Enterprise Manager's standard plug-in lifecycle: verify the download, import the archive (OPAR) onto the OMS, deploy it to the OMS and to each monitoring agent, then add and licence your targets. **24.1.2.0.0 / 13.5.3.0.0 upgrades GA (24.1.1.0.0 / 13.5.2.0.0) in place**, with the same steps; read [Upgrade notes](upgrade-notes.md) before you upgrade a production OMS.

> **Prerequisites for this page**
> - Your Enterprise Manager and Db2 versions are supported: see [Supported versions and platforms](prerequisites.md#supported-versions).
> - You have OMS access to import the OPAR and an account (for example `sysman`) with plug-in deployment privileges for `emcli`: see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).
> - The Management Repository database's `SYS` password, for the OMS deploy.

**Where to find it:** **Setup → Extensibility → Plug-ins → Databases → IBM DB2 Database → Actions → Deploy On**, or the equivalent `emcli` plug-in commands shown below.

**In this page:** Licence key · Download · Verify the download · Import the OPAR · Deploy to the OMS · Deploy to agents · Upgrade from GA · After an upgrade · Uninstall

## Licence key {#licence-key}

A valid licence key for `ip.em.xdb2` is required to monitor a target. Request one through your Integration Plumbers contact: see [Trial setup](trial.md). A key issued for the Open Beta plug-in (`ip.em.xdbb`) does not work.

You enter the key per target, in its **IBM DB2 Plug-in Licence Monitoring Credentials** set. To confirm a target's key is recognised, check its **License Info** page or its **License** metric under All Metrics. See [Licensing](targets-and-properties.md#licensing).

## Download {#download}

The plug-in ships as one OPAR per Enterprise Manager release, with the same features in each. Your Integration Plumbers contact provides the download. Use the one that matches your OMS: Enterprise Manager refuses to import an OPAR built for the other release (`Incompatible version`), because each is built with that Enterprise Manager line's own development kit.

| Enterprise Manager | OPAR | Plug-in version |
| :--- | :--- | :--- |
| 24ai | `24.1.2.0.0_ip.em.xdb2_2000_0.opar` | `24.1.2.0.0` |
| 13.5 | `13.5.3.0.0_ip.em.xdb2_2000_0.opar` | `13.5.3.0.0` |

The two lines are versioned independently, so the numbers after `24.1` and `13.5` do not have to match. Each OPAR comes with a `SHA256SUMS` file, its `build-info.txt`, and a detached signature (`.sig`) for each file.

The commands below use the 24ai version. On Enterprise Manager 13.5, substitute `13.5.3.0.0` everywhere.

## Verify the download {#verify}

Each file is signed with Integration Plumbers' release signing key. Before importing, in the download directory, verify the OPAR against its own signature first, then the checksums:

```
cosign verify-blob --key cosign.pub --signature <opar>.sig --insecure-ignore-tlog=true <opar>
cosign verify-blob --key cosign.pub --signature SHA256SUMS.sig --insecure-ignore-tlog=true SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

The OPAR comes first because `--ignore-missing` skips a file that is not there under its listed name, so it does not catch a renamed OPAR. The check runs offline. cosign 3.x also prints a `--signature` deprecation notice and a "Skipping tlog verification" warning; both are expected, because the signatures are detached and deliberately not in a public transparency log.

The release signing public key (`cosign.pub`, ECDSA P-256, sha256 `1c419e1a95947e4783d1754306539933f331666bb7804b7ad0cf007be2144a19`) is:

```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+CKrrvDIP1Ue5HmYreZXGmouP+VB
kAF+ryeo8esBrixM7EP9eWgXdWU+HOF+/++LrRfB0wOn9iV85EGyMhT1bA==
-----END PUBLIC KEY-----
```

Compare it with the `cosign.pub` delivered with a download before you trust either. The GA OPARs were signed with the same key, without changing their bytes.

## Import the OPAR {#import}

1. Copy the OPAR to the OMS host, then log in to `emcli` and enter the password when prompted:

   ```
   emcli login -username=sysman
   ```

2. Import the OPAR file:

   ```
   emcli import_update -file="/tmp/24.1.2.0.0_ip.em.xdb2_2000_0.opar" -omslocal
   ```

   `-omslocal` is for a file on the OMS host; use `-host` and `-credential_set_name` to import from an agent host instead. The plug-in then appears under **Setup → Extensibility → Plug-ins**, in the **Databases** category, as **IBM DB2 Database**. (The target types are named IBM Db2 Database and IBM Db2 Instance; the plug-in keeps its catalog name.)

## Deploy to the OMS {#deploy-oms}

1. Navigate to **Setup → Extensibility → Plug-ins**.
2. Expand the Databases folder and click **IBM DB2 Database**.
3. From the Actions menu, click **Deploy On → Management Servers** and follow the on-screen instructions.

The equivalent `emcli` command, pinned to the version you imported:

```
emcli deploy_plugin_on_server -plugin="ip.em.xdb2:24.1.2.0.0" -dbUser=SYS -dbPassword=<repository_SYS_password>
```

`-dbUser` / `-dbPassword` are the Management Repository database's `SYS` account. Enterprise Manager 24ai rejects the older `-sys_password` form; Enterprise Manager 13.5 accepts both, so the command above works on either release with `13.5.3.0.0` in place of `24.1.2.0.0`. Always pin the `:version`, on this command and on the agent deploy below.

To check deployment progress, run:

```
emcli get_plugin_deployment_status -plugin=ip.em.xdb2
```

Each deploy is asynchronous, and the OMS may restart during it: wait for the status command to report **Success** before continuing.

## Deploy to agents {#deploy-agents}

1. From the same Plug-ins page, select **IBM DB2 Database**.
2. From the Actions menu, click **Deploy On → Management Agent**.
3. Follow the on-screen instructions to select the agent hosts.

The equivalent `emcli` command:

```
emcli deploy_plugin_on_agent -plugin="ip.em.xdb2:24.1.2.0.0" -agent_names="<host>:<port>"
```

**Always pin the version**: without it, an agent that already has an earlier version of the plug-in can be reported as "already deployed" and skipped. Separate several agents with commas in `-agent_names`. `get_plugin_deployment_status` reports agent deployment progress as it does for the OMS. The plug-in deploys only to Linux x86-64 and Windows x86-64 agents.

Once the plug-in is on the OMS and at least one agent, you can add Db2 targets: see [Targets and properties](targets-and-properties.md), or let [discovery](discovery.md) propose them.

## Upgrade from GA {#upgrade}

**24.1.2.0.0 / 13.5.3.0.0 is the first in-place update of GA.** Import the new OPAR and deploy it the same way as the first install, over the existing plug-in, pinning the new `:version` on both the server and the agent commands. Targets, their credentials and their collected history are kept, except where [Upgrade notes](upgrade-notes.md) says otherwise.

1. Read [Upgrade notes](upgrade-notes.md) and decide what to do about the compliance rules, the renamed lock and session groups, and the licence key, before the upgrade reaches production.
2. [Import](#import) the new OPAR.
3. [Deploy to the OMS](#deploy-oms) with `ip.em.xdb2:24.1.2.0.0` (or `13.5.3.0.0`).
4. [Deploy to every agent](#deploy-agents) that monitors a Db2 target, in the same maintenance window. Until an agent has the new version, the metrics this release adds have nowhere to come from, so their pages stay empty, and the agent refuses the new backup job type (1.6) and runs nothing.
5. **Restart the OMS once**: `emctl stop oms`, then `emctl start oms`. Several metric groups gain columns in this release, and an OMS keeps each target type's column list in memory, so those columns stay empty, and the licence-status alert does not fire, until it restarts. A new OMS install needs no restart. See [Upgrade notes](upgrade-notes.md#restart-oms).
6. Run the [after-upgrade checks](#after-upgrade).

**Going back is not a rollback for the backup job.** The OMS keeps job type 1.6 after the upgrade, so re-deploying GA to an agent does not restore the GA backup job.

**Coming from the Open Beta?** The beta (`ip.em.xdbb`) and the released plug-in (`ip.em.xdb2`) are different plug-ins, so beta to GA is always a clean install side by side, never an in-place upgrade. Follow [Moving from the beta to GA](beta-pre-release.md).

## After an upgrade {#after-upgrade}

- **Check the target menu and pages.** Pages are renamed in this release (Home is Overview, Analysis is Locks, and so on; see [Upgrade notes](upgrade-notes.md#page-names)). The target menu shows the new names after the deploy and the OMS restart.
- **Re-apply thresholds set on the renamed lock and session groups.** Thresholds, templates and incident rules set on the GA names do not move. See [Upgrade notes](upgrade-notes.md#renamed-groups).
- **Move each licence key into its credential set**, when you are ready. Nothing breaks if you wait: see [Moving a key](targets-and-properties.md#moving-a-key).
- **Run Purge Stale Plugin Cache once per agent**, or schedule it. GA kept a small cache file per target inside the versioned plug-in home; this release moves it to the agent state directory, and the job removes the GA copies. Skipping it wastes a few KB and nothing else. See [Purge Stale Plugin Cache](jobs-and-metric-extensions.md#purge-stale-cache).
- **Open Monitoring Readiness** on a target or two. It checks the connection, licence, monitor authority, collection, monitor switches, deadlock capture, HADR and the diagnostic log live, and prints the statement that fixes each gap. See [Monitoring pages](monitoring-pages.md#monitoring-readiness).

If a limited-instance licence key's instance count fails to validate, see [Troubleshooting](troubleshooting.md#oms-licence-count): it is usually the OMS settings or the OMS certificate, not a licence problem.

**After an in-place Db2 upgrade** (for example 11.5 to 12.1), the detected Db2 version refreshes when the agent restarts or the plug-in is redeployed. To refresh it straight away, run this on the agent host:

```
emctl reload agent dynamicproperties <target name>:ip_db2_database
```

## Uninstall {#uninstall}

1. Remove every IBM Db2 Database and IBM Db2 Instance target monitored by the plug-in.
2. Undeploy the plug-in from each agent:

   ```
   emcli undeploy_plugin_from_agent -plugin=ip.em.xdb2 -agent_names="<host>:<port>"
   ```

3. Undeploy the plug-in from the OMS:

   ```
   emcli undeploy_plugin_from_server -plugin=ip.em.xdb2 -dbUser=SYS -dbPassword=<repository_SYS_password>
   ```

   On Enterprise Manager 13.5, `-sys_password=<repository_SYS_password>` also works in place of `-dbUser`/`-dbPassword`.

4. Manually delete the plug-in entry from Self Update.

**What stays behind.** A full undeploy deletes the plug-in's targets of both types and their collected data, but it does not return the OMS to the state it was in before the plug-in was installed:

- **Named credentials of the plug-in's credential types are deleted**, without an entry in Enterprise Manager's credential operation log. That includes `DB2DatabaseCreds`, `DB2InstanceCreds`, the truststore types and `DB2HostCreds`. Export their names before you undeploy if you will install the plug-in again.
- **The plug-in's job types stay registered**, although they can no longer run.
- **The association derivation rules stay** (`ip_db2_database_runs_on_host`, `ip_db2_database_hadr_partner`, `ip_db2_database_runs_on_instance` and `ip_db2_instance_runs_on_host`). With no Db2 targets left they produce nothing.
- **Older plug-in homes stay on the OMS and the agents**, and so does the plug-in's agent state directory. To clean an agent afterwards, see [Files the plug-in keeps on each agent](jobs-and-metric-extensions.md#agent-files).

Installing the plug-in again over these works.

## Related

- [Upgrade notes](upgrade-notes.md): every operator action the upgrade from GA needs
- [Prerequisites](prerequisites.md): supported versions, network access, and the monitoring role
- [Targets and properties](targets-and-properties.md): add a target and set its licence key
- [Moving from the beta to GA](beta-pre-release.md): for Open Beta users
- [Jobs](jobs-and-metric-extensions.md#purge-stale-cache): the housekeeping job to run after an upgrade
- [Troubleshooting](troubleshooting.md#deploy): fixes for deploy failures and licence-count errors
