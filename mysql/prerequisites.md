---
title: Prerequisites
nav_order: 3
---

# Prerequisites

Here are the prerequisites for deploying the plug-in and monitoring MySQL with it.
**Topics:** 2.1 Enterprise Manager and agents · 2.2 MySQL Shell for ClusterSet targets · 2.3 Network and ports · 2.4 The monitoring user · 2.5 TLS · 2.6 Unix-socket connections · 2.7 Backup-tool visibility
## 2.1 Enterprise Manager and agents
The plug-in runs inside Enterprise Manager and reaches MySQL from a management agent, so both have to be in place before you add a target.

You need:

- **An Enterprise Manager 24ai (24.1) OMS** with the plug-in deployed on the OMS. The build described in this guide is for Enterprise Manager 24ai. An EM 13.5 edition of the plug-in exists, but it is not certified in this beta — see chapters 1 and 10.
- **At least one Enterprise Manager 24ai management agent** with the plug-in deployed on it. The agent runs every collection, so it needs a network path to each MySQL endpoint it monitors.
- **Nothing else staged on the agent host** for MySQL Database and MySQL Cluster targets. The MySQL JDBC driver ships inside the plug-in — there is no driver to download or copy. MySQL ClusterSet targets have one extra prerequisite; see [2.2](#mysql-shell-for-clusterset-targets).

Where the agent runs is your choice:

- **Remote monitoring** is the normal case. The agent runs anywhere that can open a TCP connection to the MySQL port, and one agent can monitor many MySQL targets on many hosts.
- **A local agent** — an agent installed on the MySQL server host itself — is required only when you want the plug-in to connect over a Unix socket instead of TCP. See [2.6](#unix-socket-connections).

> **Note:** Deploying the plug-in on the OMS does not deploy it to agents. Deploy it to every agent that will monitor a MySQL target, as described in [3.3](install-and-upgrade.md#deploy-to-agents). Until you do, the MySQL target types are not offered for that agent on the Add Target page.

## 2.2 MySQL Shell for ClusterSet targets
The MySQL ClusterSet target type depends on one external tool being present on the agent host.

The ClusterSet target runs MySQL Shell (mysqlsh) from the agent host to read AdminAPI status. Install MySQL Shell (mysqlsh) on every agent host that will monitor a ClusterSet target and make sure it is on the agent user's PATH. Without it the plug-in cannot run AdminAPI and degrades to a repository rollup that reports `fallback_reason MYSQLSH_NOT_FOUND`; a rollup cannot assess ClusterSet-wide promotion readiness, so `dr_promotion_ready` reads 0 and the DR Promotion Ready alert raises CRITICAL until Shell is installed.

The rollup is a deliberate degradation, not an error: the target stays Up and its other columns keep collecting from the repository. Treat a CRITICAL DR Promotion Ready alert whose `fallback_reason` column reads `MYSQLSH_NOT_FOUND` as a missing prerequisite on the agent host rather than as a disaster-recovery problem on the ClusterSet.

Confirm the tool as the agent's operating-system user, not as `root`, because the agent's own PATH is what matters:

```
mysqlsh --version
```

MySQL Database and MySQL Cluster targets do not use MySQL Shell. They connect over JDBC only, and you do not need to install anything for them.

## 2.3 Network and ports
Open the paths the agent needs before you add a target. A blocked path shows up as a target that stays Down after it is added.

A MySQL Database target needs one outbound TCP path:

| Flow | Port | Used for |
|---|---|---|
| Agent host → MySQL server | The server's listening port, `3306` by default | Every JDBC collection for the target |

A MySQL Cluster target needs the same kind of path to whatever endpoint you configure on it — any member of the cluster, or a MySQL Router instance on the classic-protocol port you configured for it.

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
