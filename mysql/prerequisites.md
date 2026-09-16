---
title: Prerequisites
nav_order: 3
---

# Prerequisites

Here are the prerequisites for deploying the plug-in and monitoring MySQL with it.
**Topics:** 2.1 Enterprise Manager and agents · 2.2 MySQL Shell for ClusterSet targets · 2.3 Network and ports · 2.4 The monitoring user · 2.5 TLS · 2.6 Unix-socket connections · 2.7 Backup-tool visibility · 2.8 Sizing and capacity
## 2.1 Enterprise Manager and agents
The plug-in runs inside Enterprise Manager and reaches MySQL from a management agent, so both have to be in place before you add a target.

You need:

- **An Enterprise Manager 24ai (24.1) or 13.5 OMS** with the plug-in deployed on the OMS. Both the EM 24ai and EM 13.5 editions of the plug-in are certified in this beta — see chapters 1 and 10.
- **At least one Enterprise Manager 24ai or 13.5 management agent** with the plug-in deployed on it. The agent runs every collection, so it needs a network path to each MySQL endpoint it monitors.
- **MySQL Connector/J on every agent host** that will monitor a MySQL target, placed in the agent's `ip_plugin/xmyb/lib` directory before the plug-in is deployed to that agent. The driver is not distributed inside the plug-in; see [2.9](#mysql-connectorj-on-agent-hosts) for the version, the download check and the exact directory. MySQL ClusterSet targets have one further prerequisite; see [2.2](#mysql-shell-for-clusterset-targets).

Where the agent runs is your choice:

- **Remote monitoring** is the normal case. The agent runs anywhere that can open a TCP connection to the MySQL port, and one agent can monitor many MySQL targets on many hosts.
- **A local agent** — an agent installed on the MySQL server host itself — is required only when you want the plug-in to connect over a Unix socket instead of TCP. See [2.6](#unix-socket-connections).

> **Note:** Deploying the plug-in on the OMS does not deploy it to agents. Deploy it to every agent that will monitor a MySQL target, as described in [3.3](install-and-upgrade.md#deploy-to-agents). Until you do, the MySQL target types are not offered for that agent on the Add Target page.

## 2.2 MySQL Shell for ClusterSet targets
Besides Connector/J ([2.9](#mysql-connectorj-on-agent-hosts)), which every target type needs, the MySQL ClusterSet target type depends on one external tool being present on the agent host.

The ClusterSet target runs MySQL Shell (mysqlsh) from the agent host to read AdminAPI status. Install MySQL Shell (mysqlsh) on every agent host that will monitor a ClusterSet target and make sure it is on the agent user's PATH. Without it the plug-in cannot run AdminAPI and degrades to a repository rollup that reports `fallback_reason MYSQLSH_NOT_FOUND`; a rollup cannot assess ClusterSet-wide promotion readiness, so `dr_promotion_ready` reads 0 and the DR Promotion Ready alert raises CRITICAL until Shell is installed.

The rollup is a deliberate degradation, not an error: the target stays Up and its other columns keep collecting from the repository. Treat a CRITICAL DR Promotion Ready alert whose `fallback_reason` column reads `MYSQLSH_NOT_FOUND` as a missing prerequisite on the agent host rather than as a disaster-recovery problem on the ClusterSet.

**A member Shell cannot reach.** Once MySQL Shell connects through one listed endpoint, the AdminAPI opens its own session to every member Group Replication still considers online — not only the members the endpoint list ([2.3](#network-and-ports)) used to connect. A network path that reaches one listed member but not another therefore still degrades ClusterSet health, even though the endpoint list itself worked: `fallback_reason` reads `MEMBER_UNREACHABLE`, `dr_promotion_ready` reads 0, and the DR Promotion Ready alert raises CRITICAL after two consecutive collections until the path is open. The remedy is the same one 2.3 already asks for: a path from the agent host to every member of every cluster, on each member's MySQL port — not only the members you listed on the target. See [Troubleshooting](troubleshooting.md#clusterset).

Confirm the tool as the agent's operating-system user, not as `root`, because the agent's own PATH is what matters:

```
mysqlsh --version
```

MySQL Database and MySQL Cluster targets do not use MySQL Shell. They connect over JDBC only, through the Connector/J driver you place on the agent host ([2.9](#mysql-connectorj-on-agent-hosts)), and need nothing else.

**Kerberos on a ClusterSet target.** When the target carries a Kerberos Configuration File ([4.1](targets-and-properties.md#target-properties)), the plug-in runs MySQL Shell with the `authentication_kerberos_client` plug-in and no password: the credential is the ticket in the agent operating-system user's default credential cache, and `KRB5_CONFIG` is set to the target's file. Three things must therefore be true on the agent host, none of which the plug-in can arrange for you: the Kerberos client libraries are installed; the agent's operating-system user holds a keytab for the monitoring principal with an unattended refresh (`k5start`, or a scheduled `kinit -kt`), because a scheduled collection cannot type a password; and `klist` run as that user shows a valid ticket. MySQL Shell's own package ships the client plug-in. Every ClusterSet member must accept the principal through the server's `authentication_kerberos` plug-in, and MySQL Shell opens its own session to every member, so the account must exist cluster-wide. Kerberos does not pass through MySQL Router: give a Kerberos ClusterSet target member endpoints (a node list, 4.1), not a Router port. The `fallback_reason` column names each of these when it is missing — `KERBEROS_TICKET` when the Kerberos exchange itself fails (a missing or expired ticket is the usual cause; an unreachable KDC, clock skew or a missing service principal look the same to MySQL Shell), `KERBEROS_NOT_SUPPORTED` for a Router endpoint, `KERBEROS_CLIENT_UNAVAILABLE` when MySQL Shell cannot load its Kerberos client plug-in, `KERBEROS_CONFIG_UNREADABLE` when the file itself cannot be read, and `AUTH_FAILED` for a member that does not accept the principal — each with its remedy in [Troubleshooting](troubleshooting.md#clusterset). The credential set's password is not used on this path: the ticket is the credential, and a target registered for Kerberos needs no password at all.

## 2.3 Network and ports
Open the paths the agent needs before you add a target. A blocked path shows up as a target that stays Down after it is added.

A MySQL Database target needs one outbound TCP path:

| Flow | Port | Used for |
|---|---|---|
| Agent host → MySQL server | The server's listening port, `3306` by default | Every JDBC collection for the target |

A MySQL Cluster target needs the same kind of path to whatever endpoint you configure on it — any member of the cluster, or a MySQL Router instance on the classic-protocol port you configured for it.

Both container types accept a **comma-separated list** of endpoints in `(Router) Host` / `(Router) Port` ([4.1](targets-and-properties.md#target-properties)); every member you list needs this same path from the agent host.

A MySQL ClusterSet target needs two things:

- The agent's JDBC path to the host and port configured on the target, normally a MySQL Router endpoint.
- A path from the agent host to **every member of every cluster in the ClusterSet**, on each member's MySQL port, because MySQL Shell opens those connections itself when it reads AdminAPI status.

> **Note:** mysqlsh member discovery uses hostnames, so the agent host must resolve every cluster member's FQDN even when the database targets themselves are configured by IP address.

Check the host firewall on the database side (`firewalld`, `nftables`, cloud security groups) as well as any network firewall in between, and confirm the server's `bind-address` accepts connections from the agent's address.

## 2.4 The monitoring user
The plug-in connects to MySQL as an ordinary read-only account. Create it on each server before you add the target.

Run these two statements as an account that can create users:

```sql
CREATE USER 'em_monitoring'@'%' IDENTIFIED BY '<strong password>';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'em_monitoring'@'%';
```

No SUPER and no write privilege is required. Because the SELECT grant is global, it already covers performance_schema, the mysql schema, mysql.backup_history and PERCONA_SCHEMA — no further grant is needed for any metric group or for backup monitoring.

What each privilege buys:

| Privilege | Used for |
|---|---|
| `SELECT` on `*.*` | Every collection that reads a table or view — `performance_schema` (including the Group Replication status tables), the `sys` schema, the `mysql` schema and the backup history tables |
| `PROCESS` | Server-wide session and InnoDB engine status, including the process list and per-user activity |
| `REPLICATION CLIENT` | `SHOW REPLICA STATUS` and `SHOW BINARY LOG STATUS` |

> **Note:** Narrow the `'%'` host clause to your agent's subnet if your security policy requires it. The agent connects over TCP, so the account's host clause has to match the agent's address as MySQL sees it — not `localhost`. Socket-connected targets are the exception; see [2.6](#unix-socket-connections).

> **Note:** On Group Replication and InnoDB ClusterSet deployments `CREATE USER` and `GRANT` replicate like any other write. Run the two statements once on the (global) primary and the account exists on every member.

## 2.5 TLS
Each target chooses its own transport security through the **TLS Mode** property; nothing is inherited from the server or from the agent.

The property recognizes four values, and leaving it empty is meaningful in its own right:

| Value | Behavior |
|---|---|
| *(empty)* | Same as `disabled` — the agent connects without TLS. |
| `disabled` | The agent connects without TLS. |
| `required` | The agent connects only if the session is encrypted. |
| `verify_ca` | Truststore-backed mode. Not available in this release. |
| `verify_identity` | Truststore-backed mode. Not available in this release. |

Three behaviors matter operationally:

- **An empty TLS Mode means plaintext.** Leaving the property blank is treated exactly as `disabled`, not as `required`. Set it explicitly on every target where the connection has to be encrypted.
- **`required` fails closed.** If the server cannot give the agent an encrypted session, the connection fails with an explicit `SQLException` and the target goes Down. There is no silent fallback to plaintext, so a target that is Up under `required` connected over TLS.
- **Any non-empty value the plug-in does not recognize fails closed to `required`.** A typo in the property is treated as `required` rather than as `disabled`, so it cannot quietly switch encryption off — but an *empty* property is not a typo, and follows the first rule above.

> **Note:** verify_ca and verify_identity are not available in this release — the truststore properties they depend on are deferred — and only required and disabled are validated. Those two modes are absent from the target pages and from EM CLI, so use `required` where you need an encrypted session. A ClusterSet health check configured with `verify_ca` or `verify_identity` reports `TLS_TRUSTSTORE_REQUIRED` instead of connecting, so use `required` (or `disabled`) for ClusterSet targets as well.

## 2.6 Unix-socket connections
A MySQL server that shares a host with its management agent can be monitored over a Unix socket instead of TCP.

Requirements:

- The management agent runs on the MySQL server host — a local agent, as described in [2.1](#enterprise-manager-and-agents).
- The agent's operating-system user can read and write the socket file. Confirm the path on the server with `SELECT @@socket;`.
- The monitoring account exists as `'<user>'@'localhost'`. A socket connection arrives as `localhost`, and MySQL matches the most specific host value first, so create the account explicitly for that host value:

```sql
CREATE USER 'em_monitoring'@'localhost' IDENTIFIED BY '<strong password>';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'em_monitoring'@'localhost';
```

On the target, set **Unix Socket Path** to the socket file and leave **Host** empty.

> **Note:** A target configured with both a host and a socket path connects over TCP. Leave Host empty to force the socket connection.

> **Note:** MySQL matches the most specific *host* value first, and among rows that share a host value a named user beats the anonymous one. An anonymous account (`''@'localhost'`) — shipped as a legacy default by some installations, and sometimes left behind by test fixtures — therefore shadows `'em_monitoring'@'%'` on a local connection, but it does not shadow `'em_monitoring'@'localhost'`. That is exactly why this section asks for the explicit `@'localhost'` account. If a socket target still fails to authenticate, list any anonymous rows with `SELECT user, host FROM mysql.user WHERE user = '';` and drop the ones you do not need.

A socket connection authenticates a `caching_sha2_password` monitoring account on its own after a `mysqld` restart, with no TLS and no operator action: the plug-in registers a socket-aware client authentication plug-in for socket connections (see the release note in `upgrade-notes.md` for the mechanism). TLS Mode ([2.5](#tls)) means the same thing on a socket target as on a TCP one. The Unix Socket Path must be `mysqld`'s own socket: a Unix socket fronted by a proxy that forwards to the server over TCP (MySQL Router `socket=`, ProxySQL) is not a secure transport in the server's eyes, and the socket-aware plug-in — like the `mysql` client — will not authenticate a `caching_sha2_password` account through it; point such a target at the proxy's TCP port instead.

## 2.7 Backup-tool visibility
The plug-in reports backup age and backup failures by reading the history tables that backup tools write into MySQL, so what it can see depends on which tool you run and how you run it.

| Tool | History table | Written when |
|---|---|---|
| MySQL Enterprise Backup (MEB) | `mysql.backup_history` | On every run, by default |
| Percona XtraBackup (PXB) | `PERCONA_SCHEMA.xtrabackup_history` | Only when the backup command includes `--history` |

Both tables are already readable under the monitoring account in [2.4](#the-monitoring-user), because its `SELECT` is global.

When a tool's history table is not present on the server, the plug-in reports that tool as not detected and raises no alert; the other tool's metrics carry on collecting. A site that runs only one of the two tools sees the other reported as not detected, and that is the intended behavior rather than a fault — it is what keeps a shop that never installed MEB from seeing a permanent false "no backups" alarm.

> **Note:** MEB writes history by default and `--no-history-logging` turns it off. There is no `--backup-history` flag to add — MEB does not recognize one and errors if you pass it. If MEB backups are not appearing, look for `--no-history-logging` in the backup job rather than for a missing flag.

> **Note:** Logical dumps (`mysqldump`, `mysqlpump`, the MySQL Shell dump utilities) and storage or array snapshots leave no server-side record at all. No SQL-based collector, this plug-in included, can see them. An estate backed up only that way correctly shows no backup history.

**Failure detection is asymmetric between the two tools.** MEB writes a history row when a run fails, so the failed-backup condition works on MEB. XtraBackup writes no row for a failed run, so on XtraBackup-only estates that condition can never fire and backup **age** is the failure signal instead. Size the age thresholds ([7.1](alerts-and-thresholds.md#default-thresholds)) to your backup cadence with that in mind.

For the cluster pattern — back up on one member and monitor any member, because history rows replicate like any other write — and for the full tool-by-tool detail, see [backup monitoring](backup-monitoring.md).


## 2.8 Sizing and capacity
Plan the agent hosts and the repository before you add more than a handful of targets. The numbers here were measured on 2026-09-10 on our own lab, on the shipped default collection schedules, with the plug-in's current collection architecture: **the agent runs every collection as its own short-lived JVM**, one per collection item per target. That architecture is what sets the cost per target, and a single co-located lab host showed exactly what happens when it is exceeded.

**What one database target costs.**

| Resource | Measured, per `ip_mysql_database_beta` target at default schedules |
|---|---|
| Collection processes | about **14 JVM launches per minute** (Response, wait profile and its summary every minute; about 56 items every 5 minutes; configuration once a day) |
| Agent-host CPU | about **0.3 of a vCPU, sustained** (18 targets drove the `oracle` user to ~525 % of an 8-vCPU host; each launch costs 2 to 3 CPU-seconds including the JDBC connect) |
| Repository ingest | about **52,000 metric rows per hour**, 1.2 million per day |

Cluster and ClusterSet targets are lighter on the repository but each health collection also runs MySQL Shell ([2.2](#mysql-shell-for-clusterset-targets)), which is a further CPU burst of about a second on the agent host; an endpoint-list target with six members costs the same as one.

**Where the repository rows come from.** Five keyed groups are 70 percent of the ingest; the rest of the 59 groups together are the other 30 percent.

| Metric group | Rows per hour per target | Why |
|---|---|---|
| Memory by Event (`SysMemoryByEvent`) | ~15,000 | one row per Performance Schema memory instrument (about 1,200), every 5 minutes |
| File I/O (`SysIoByFile`) | ~8,600 | one row per open file, every 5 minutes |
| Statements by latency, by execution count, by first seen | ~11,400 | three top-25 rankings, every 5 minutes |
| I/O by wait class (`SysIoByWait`) | ~2,500 | |
| Statement digest profile (Query Analytics Trends, 5.1) | ~2,400 | top 25 per 5-minute collection |
| Wait profile (Top Waits, 5.1) | ~1,400 | active events only, every minute |

**Agent hosts: the rule.** Give the plug-in **dedicated agent hosts** and plan **two database targets per vCPU** on them, which leaves headroom for cluster targets, collection bursts and the agent's own work. Never place these targets on an agent that shares a host with the Oracle Management Service or the repository database: on our 8-vCPU lab host that carries all three, 18 targets starved the repository's log writer of CPU — commits queued for seconds (`log file sync` averaging over 2 s while the disk sat idle), the metric loader's upload threads stuck on commit, and the OMS restarted itself repeatedly without finishing initialisation.

| Dedicated agent host | Database targets to plan for |
|---|---|
| 4 vCPU | 8 |
| 8 vCPU | 16 |
| 16 vCPU | 32 |

Spread a larger estate across several agents — the bulk-onboarding script ([4.7](targets-and-properties.md#bulk-onboarding-and-migration)) takes the agent per row — and keep the composite cluster and ClusterSet targets on the same agent as their members so a health collection does not add a network hop.

**Repository: reduce what you do not read.** At 100 targets the default schedules load about 5 million rows an hour into the repository. Size the repository host per Oracle's Enterprise Manager sizing guidance for a large deployment, and reduce the collection frequency of the high-cardinality groups you do not use minute by minute. From the target's **Metric and Collection Settings**: move Memory by Event and File I/O to every 30 minutes and the three statement rankings to every 15 minutes, which removes roughly two thirds of the ingest with no loss to the Home, Query Analytics Trends or Top Waits pages — those read the statement digest profile and the wait profile, which should stay at their defaults. Disabling Memory by Event entirely is reasonable in an estate that does not investigate memory instrument by instrument. Changing a schedule also changes the Week and Month rollup estimates described under Query Analytics Trends and Top Waits in [5.1](monitoring-pages.md#mysql-database-pages) for that group only.

**Recognising overload.** The symptoms arrive in this order: the Week and Month windows on the trend pages stay empty and the 24 Hours window stops advancing; `emctl status oms -details` on the OMS reports the management server down with "PBS may not be up" while the console still serves; the WebLogic server log shows `[STUCK] ExecuteThread` entries whose stacks end in `MetricLoadShared.flushRows` waiting on a JDBC commit; the repository shows `log file sync` waits of seconds with `log file parallel write` in single-digit milliseconds; and the agent log reports the OMS upload URL answering "Context not fully initialized - rejecting request". A collection-error count of zero throughout is normal — the agent is collecting, the repository cannot absorb it.

**Relief, in order:** put the targets you can spare into a blackout with an explicit duration (`emcli create_blackout -name=<name> -add_targets="<target>:ip_mysql_database_beta;…" -reason="<reason>" -schedule="duration:168:00"` for seven days) so the launch rate drops immediately. Give the duration as hours and minutes: on Enterprise Manager 24ai `duration:-1` creates a one-hour blackout, not an indefinite one. `emcli stop_blackout -name=<name>` ends it early and leaves its record behind, so run `emcli delete_blackout -name=<name>` before creating another blackout with the same name. Once the launch rate has dropped, restart the OMS (`emctl stop oms -all` then `emctl start oms`), then move targets to additional agents or lower the schedules above before lifting the blackout. Restarting the OMS without reducing the load only repeats the stall.

**Why the cost grows this way.** Each metric group collects in its own process on its own interval, so the process launch rate grows with the number of targets times the number of groups. The figures above apply to this release.

## 2.9 MySQL Connector/J on agent hosts
The plug-in reaches MySQL through **MySQL Connector/J**, Oracle's JDBC driver. Connector/J is licensed under the GPL with Oracle's Universal FOSS Exception, or under a MySQL commercial licence, so it is not distributed inside the plug-in. You place one copy on every management agent host that monitors a MySQL target, and the plug-in loads it from there. This applies to MySQL Database, MySQL Cluster and MySQL ClusterSet targets alike, and to the Run EXPLAIN job ([8.1](jobs.md#run-explain)).

**Which version.** Connector/J **8.4.0** is the version this release is tested with, against MySQL 8.0, 8.4 and 9.x servers. Later 8.4.x and 9.x releases are expected to work; if a collection stops after you install a newer driver, go back to 8.4.0 and tell us ([1.4](index.md#beta-status)). The legacy `mysql-connector-java-*.jar` name (Connector/J 5.1 and 8.0) is not picked up: the plug-in looks for `mysql-connector-j-*.jar`.

**Where it goes.** The directory is `<agentStateDir>/ip_plugin/xmyb/lib/`, where `<agentStateDir>` is the agent's instance directory. `emctl status agent` prints it as **Agent Home** (the line above it, **Agent Binaries**, is a different directory):

```
$ /u01/app/em/agent/agent_24.1.0.0.0/bin/emctl status agent | grep 'Agent Home'
Agent Home             : /u01/app/em/agent/agent_inst
```

With that value the driver directory is `/u01/app/em/agent/agent_inst/ip_plugin/xmyb/lib/`. On Enterprise Manager 13.5 the instance directory usually sits under the agent home, for example `/u01/app/em/agent/agent_13.5.0.0.0/agent_inst`. The directory survives plug-in upgrades and undeploys; the plug-in never writes files into it, though a collection creates the empty directory if it is missing. Keep **exactly one** `mysql-connector-j-*.jar` in it.

**Steps, on every agent host**, as the agent's operating-system user:

1. Download `mysql-connector-j-8.4.0.jar` and check it. The plain jar is on Maven Central at `https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.4.0/mysql-connector-j-8.4.0.jar`; its SHA-256 is:

   ```
   d77962877d010777cff997015da90ee689f0f4bb76848340e1488f2b83332af5  mysql-connector-j-8.4.0.jar
   ```

   The same jar is inside the *Platform Independent* archive on `dev.mysql.com/downloads/connector/j` (version 8.4.0 is under *Archives*). The checksum shown on that page is for the archive, not the jar; the value above is the jar's.
2. Create the directory and copy the jar into it, readable by the agent user:

   ```
   AGENT_HOME=$(emctl status agent | awk -F': *' '/Agent Home/ {print $2}')
   install -d -m 0755 "$AGENT_HOME/ip_plugin/xmyb/lib"
   install -m 0644 mysql-connector-j-8.4.0.jar "$AGENT_HOME/ip_plugin/xmyb/lib/"
   shasum -a 256 "$AGENT_HOME/ip_plugin/xmyb/lib/mysql-connector-j-8.4.0.jar"
   ```

3. Deploy the plug-in to the agent ([3.3](install-and-upgrade.md#deploy-to-agents)). If the plug-in is already deployed there, nothing needs restarting: the next collection uses the jar.

**Permissions.** The jar must be readable by the agent's operating-system user, which runs every collection, and by the operating-system user of the target's Host Preferred Credential, which runs Run EXPLAIN ([8.1](jobs.md#run-explain)). They are usually the same user; mode `0644` in a `0755` directory covers both either way.

**Upgrading the driver.** Replace the jar with the new one, keeping exactly one in the directory. The next collection uses it; the plug-in does not need redeploying.

**Licensing, for the record.** Integration Plumbers does not redistribute MySQL Connector/J and has not sought a redistribution licence from Oracle: you obtain the driver from Oracle under the licence that applies to you, the GPL version 2 with the Universal FOSS Exception or a MySQL commercial licence, and it never appears in the plug-in's own third-party notices. The components that do ship inside the plug-in, and their licences, are listed in `THIRD-PARTY-NOTICES.txt`, generated from the build's software bill of materials and deployed next to the plug-in's program in the agent's plug-in `scripts` directory; the SBOM itself is delivered beside the plug-in archive.

**When it is missing or wrong.** Every collection of every MySQL target on that agent, and every Run EXPLAIN job, stops with one message that names the directory; the target does not report a MySQL problem. The messages and what to do about each are on the Troubleshooting page, under *Install and deploy*; the one you will see first is:

```
MySQL Connector/J not found: no mysql-connector-j-*.jar in /u01/app/em/agent/agent_inst/ip_plugin/xmyb/lib; files present: none. Place exactly one Connector/J jar there.
```
