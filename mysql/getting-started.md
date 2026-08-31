---
title: Getting started
nav_order: 2
---

# Getting started

The shortest path from a downloaded archive to a MySQL target you can actually look at.

> **Prerequisites for this page**
> - Enterprise Manager access that can import an OPAR and deploy plug-ins, for example `sysman`. See [Prerequisites](prerequisites.md#enterprise-manager-and-agents).
> - A **Linux** Management Agent on, or with network reach to, each MySQL server. Windows agents are not supported in this release.
> - The ability to create an account on the MySQL server you want to monitor. See [Prerequisites](prerequisites.md#the-monitoring-user) for the exact grants.
> - Your **beta licence key** for `ip.em.xmyb`, from your Integration Plumbers contact.

**In this page:** Before you start · Install the plug-in · Add your first target · Check it worked · What to look at first · If something is wrong

If you are reading this, you have agreed to try something before it is finished, and your time is the thing we are spending. So this page is deliberately the short version: six steps, roughly twenty minutes, with links to the detail rather than the detail itself.

**The one thing worth knowing before you start:** a beta target will come **Up** without a licence key and then collect nothing but availability. That surprises people, because the target looks healthy in All Targets while every metric page stays empty. Enter the key when you create the target and the question never arises.

The six steps below are: what to have ready, installing, adding a target, confirming it works, where to look first, and what to do if it does not.

## 1. Before you start {#before}

Have these to hand:

| What | Notes |
|---|---|
| The OPAR that matches your EM line | `24.1.9.N.0` for Enterprise Manager 24ai, `13.5.9.N.0` for 13.5. They are **not** interchangeable — EM refuses the other one at import with `Incompatible version` |
| The MySQL server's address and port | Default `3306`. A local agent can use the Unix socket instead — see [Prerequisites](prerequisites.md#unix-socket-connections) |
| A monitoring account on that server | `SELECT`, `PROCESS` and `REPLICATION CLIENT`. The exact statements are in [Prerequisites](prerequisites.md#the-monitoring-user) |
| Your beta licence key | One per licensed MySQL Database target. Cluster and ClusterSet targets are containers and need no key |

If you plan to monitor an InnoDB ClusterSet, also install **MySQL Shell** (`mysqlsh`) on the agent host now — see [Prerequisites](prerequisites.md#mysql-shell-for-clusterset-targets). Without it ClusterSet health falls back to a repository rollup that cannot assess DR promotion readiness.

## 2. Install the plug-in {#install}

Import the archive, deploy it to the management server, then to the agent that will do the monitoring. Full procedure in [Install and upgrade](install-and-upgrade.md).

```
emcli login -username=<em administrator>
emcli import_update -file=/tmp/<artifact>.opar -omslocal
emcli deploy_plugin_on_server -plugin=ip.em.xmyb
emcli get_plugin_deployment_status -plugin=ip.em.xmyb      # wait for Success
emcli deploy_plugin_on_agent -plugin=ip.em.xmyb -agent_names="<agent host>:<port>"
```

On **EM 24ai** the server deployment prompts for the repository SYS password; on **13.5** pass it as `-sys_password`. Some drops move target metadata, in which case the OMS deployment restarts the OMS — the status command tells you when it is back.

Deploy the agent side in the same maintenance window as the OMS side. Until you do, metrics added by that drop show no data on their pages.

## 3. Add your first target {#add-target}

In the console: **Setup → Add Target → Add Targets Manually**, choose the **MySQL Database (Beta)** type, and fill in the host, port, monitoring credentials and the **License Key**.

Put `(Beta)` in the target name. Auto-discovered beta targets get that suffix automatically, and it is what stops a beta target and a GA target from colliding in All Targets and in notifications.

With `emcli`:

```
emcli add_target -name="<server> (Beta)" -type=ip_mysql_database_beta -host=<agent host> \
  -properties="ip_mysql_database_host:<mysql host>;ip_mysql_database_port:3306;ip_mysql_database_license:<key>" \
  -credentials="ip_mysql_database_username:<user>;ip_mysql_database_password:<password>"
```

`-host` is the **agent** host — the machine doing the monitoring — while `ip_mysql_database_host` is the MySQL server. They are often different machines, and swapping them is the most common mistake at this step.

Every property is listed in [Targets and properties](targets-and-properties.md#target-properties).

## 4. Check it worked {#check}

Within a few minutes the target should show **Up**, its home page should fill in, and the **License** metric should report `Active`.

Those are three separate signals and they fail independently:

- **Up** means the agent reached MySQL and got a response. If it stays Down, the problem is connectivity or credentials.
- **`License` = `Active`** means the key was accepted. Anything else stops ordinary collection — see [Troubleshooting](troubleshooting.md#licence).
- **A populated home page** means collections are running and uploading.

A target that is Up with an empty home page is almost always the licence key.

## 5. What to look at first {#first-look}

Open the target's home page and work down the left-hand navigation:

1. **Overview** — availability, configuration summary, connections and buffer-pool usage at a glance.
2. **Connections → Database Processes** — who is connected and what they are running right now. The fastest way to confirm the plug-in is seeing your real workload.
3. **Performance → Query Analyzer** — the statement digests, ordered by the cost you care about. This is the page most beta feedback has been about, so it is worth forming an opinion early.
4. **Performance → InnoDB Buffer Pool** — hit rate and usage, and the source of two of the shipped alert thresholds.

Every page is described in [Monitoring pages](monitoring-pages.md), and every metric in the [Metrics reference](metrics-reference.md).

## 6. If something is wrong {#wrong}

Start with [Troubleshooting](troubleshooting.md) — it opens with the licence-gate symptoms, which account for most of what people hit in the first hour.

If the answer is not there, that itself is useful to us. Send it to the beta feedback contact supplied with your download, with:

- the plug-in version (`emcli list_plugins_on_server`)
- your EM version (24ai or 13.5)
- the MySQL version and edition
- the metric group or console page involved
- any deploy log, agent log or collection-error text

---

**In short:** installing the beta is the standard plug-in lifecycle — import, deploy to the OMS, deploy to the agent, add a target — with one addition that is easy to miss, the licence key, and one naming convention, the `(Beta)` suffix.

You are running this before it is finished, which means the rough edges you find are the ones we get to fix before general availability. Findings from beta customers go straight into GA certification, so the half hour you spend telling us something looks wrong is worth considerably more than the half hour it costs you.

That was the six steps promised at the top: what to have ready, install, add a target, confirm, where to look, and what to do when it goes wrong. Next: [Prerequisites](prerequisites.md) for the full requirements, or [Troubleshooting](troubleshooting.md) if something already needs fixing.
