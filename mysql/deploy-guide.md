---
title: Deployment guide
nav_order: 3.5
---

# Deploying the MySQL Plug-in — Customer Guide

This guide takes you from the delivered `.opar` file to a monitored MySQL
target. Read the [MySQL plug-in User Guide](index.md) first for what this
release is and is not — chapter 1.3 for what is certified, and the boundaries
list at the end of 10.1 for what is not.

## 1. What you need

- **Enterprise Manager 24ai or 13.5** (OMS + at least one management
  agent). Two artifacts ship, one per EM line — import the one that matches
  your OMS: the 24ai artifact into a 24ai OMS, the 13.5 artifact into a 13.5
  OMS. The 13.5 console render is not yet certified; see the release notes in
  the [user guide](index.md).
- **Network path from the agent to each MySQL server** on its listening
  port (default 3306). Remember host firewalls (`firewalld` etc.) on the
  database side.
- **Nothing else on the agent for standard targets.** The MySQL JDBC driver
  ships inside the plug-in — there is no driver to stage.
- **For InnoDB ClusterSet targets only:** MySQL Shell (`mysqlsh`) installed
  and on the PATH of the monitoring agent's host.

### Which artifact do I need?

The plugin ships **one artifact per EM line**, because EM accepts a plugin
only if it was built with that EM version's development kit — the version
number alone does not decide compatibility:

| Your EM version | Artifact | Example filename |
|---|---|---|
| EM 24ai (24.1) | `24.1.x.y.z` OPAR | `24.1.9.75.0_ip.em.xmys_2000_0.opar` |
| EM 13.5 | `13.5.x.y.z` OPAR | `13.5.9.33.0_ip.em.xmys_2000_0.opar` |

Importing the wrong artifact is refused outright with
`Internal Error: Incompatible version`. The two EM lines version
independently — the current pair is `24.1.9.75.0` and `13.5.9.33.0` — so do
not read the `x.y.z` after the EM prefix as a shared release number. Match
the artifacts by the release date and release notes they ship with; the
accompanying `build-info.txt` and `SHA256SUMS` in the release package state
the source commit each was built from and each artifact's checksum.

## 2. Import and deploy the plug-in

Copy the `.opar` to the OMS host, then as the EM software owner:

```
emcli login -username=sysman
emcli import_update -file=/tmp/<file>.opar -omslocal
emcli deploy_plugin_on_server -plugin=ip.em.xmys -sys_password=<sys password>
emcli get_plugin_deployment_status -plugin=ip.em.xmys     # repeat until Success
```

Then deploy to each agent that will monitor MySQL targets — via the console
(**Setup → Extensibility → Plug-ins → MySQL Database → Deploy On → Management
Agent**) or:

```
emcli deploy_plugin_on_agent -agent_names="<host>:<port>" -plugin=ip.em.xmys
```

Upgrading from an earlier plug-in version? Deploy the new version the same
way (no undeploy first) and read [upgrade notes](upgrade-notes.md) for
release-specific steps.

## 3. Create the monitoring user

On each MySQL server (least-privilege — no SUPER, no write access to your
data):

```sql
CREATE USER 'em_monitoring'@'%' IDENTIFIED BY '<strong password>';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'em_monitoring'@'%';
```

Because the `SELECT` grant above is global (`ON *.*`), it already covers
`performance_schema`, the `mysql` schema, `mysql.backup_history` and
`PERCONA_SCHEMA` — no further grant is needed.

Notes:

- Restrict the `'%'` host to your agent subnet if your policy requires it —
  the agent connects over TCP, so the account must match the agent's
  address as MySQL sees it (not `localhost`).
- **Group Replication / ClusterSet:** `CREATE USER` replicates. Create the
  account once on the (global) primary and it exists on every member.
- Backup monitoring reads `mysql.backup_history` (MySQL Enterprise Backup)
  and `PERCONA_SCHEMA.xtrabackup_history` (Percona XtraBackup); both are
  already covered by the global `SELECT` grant. See
  [backup monitoring](backup-monitoring.md) for tool-side setup.

## 4. Add targets

Self-managed MySQL on a monitored host is **auto-discovered** (one proposed
target per listening `mysqld`); promote the proposed target and supply the
`em_monitoring` credentials. Managed-cloud MySQL (RDS, Aurora, Cloud SQL) has
no host process to discover — add it manually with endpoint host + port.
Details for both paths: [discovery.md](discovery.md).

For InnoDB Cluster and ClusterSet composite targets, add the
`ip_mysql_cluster_beta` / `ip_mysql_clusterset_beta` target types the same way
(manual add). A bulk-onboarding and migration chapter (EMCLI-scripted) is
being published separately.

## 5. Associate the compliance standards (optional but recommended)

The plug-in ships MySQL configuration compliance standards (author
`INTEGRATION_PLUMBERS`, visible under **Enterprise → Compliance →
Library**). Associate them with your targets from the Compliance Library
UI, or with emcli — note the two different name forms:

```
emcli associate_cs_targets -name=<internal standard name> -version=1 \
      -author=INTEGRATION_PLUMBERS -target_list="<target display name>"
```

(`-name` takes the standard's *internal* name from the library listing;
`-target_list` takes the target *display name* alone.)

## 6. Verify

1. The target shows **Up** within a couple of minutes of being added.
2. **All Metrics** (target menu → Monitoring → All Metrics) shows the
   metric groups populating on their schedules.
3. To force a collection instead of waiting, on the agent host:
   `emctl control agent runCollection "<target name>":ip_mysql_database_beta <MetricGroup>`

## 7. If something is wrong

| Symptom | Check first |
|---|---|
| Target stays Down after add | Credentials; agent→MySQL network path and DB-host firewall; the user's host clause matches the agent's source address |
| Target Up, one metric group empty | That group's prerequisite (e.g. backup grants, replication role) — a group that errors degrades alone, see its Collection Errors entry |
| ClusterSet health shows `TLS_TRUSTSTORE_REQUIRED` | Expected for `VERIFY_CA`/`VERIFY_IDENTITY` modes — use `REQUIRED`; truststore credential support is not available in this release |
| ClusterSet health in fallback mode | `mysqlsh` missing from the agent host's PATH |
| Backup metrics empty | Grants + tool visibility rules in [backup monitoring](backup-monitoring.md) |
| Plug-in import refused ("Incompatible version") | You are importing the wrong edition for your OMS — see "Which artifact do I need?" above; EM 13.5 needs the `13.5.x` artifact, EM 24ai the `24.1.x` one |
