---
title: What's new
nav_order: 1
---

# Release notes

**Topics:** 10.2 Open Beta — 24.1.9.N.0 / 13.5.9.N.0 (2026-09-01) · 10.1 Early Access build (2026-08-18)

## 10.2 Open Beta — 24.1.9.N.0 / 13.5.9.N.0 (2026-09-01)

The Open Beta drop. It is a **separate plug-in** from the Early Access build below and from the GA release to come (`ip.em.xmyb`, target types `ip_mysql_database_beta`, `ip_mysql_cluster_beta`, `ip_mysql_clusterset_beta`); see [the Open Beta notice](beta-pre-release.md) for the terms of use and the install path, and [upgrade notes](upgrade-notes.md) for operator actions. Both editions are built from the same commit; the exact versions are in `build-info.txt` beside the artifacts.

#### Functionality Added or Changed
- **Licensing.** Every MySQL Database target carries a **License Key** property ([4.1](targets-and-properties.md#target-properties)) and a `License` metric group (status, licensed, days remaining, expiration, type, instances, customer), collected on the agent every 15 minutes and again whenever the key changes. Two default thresholds ship with it — CRITICAL when the licence is not active, WARNING/CRITICAL at 30/7 days before expiry — taking the shipped threshold count from 17 to **19** ([7.1](alerts-and-thresholds.md#default-thresholds)). While the status is anything but `Active`, every other metric group on that target reports `Collection stopped by license status: …` until a valid key is entered; availability keeps reporting so the target stays Up. Keys are issued per plug-in: a GA key on the beta (or a beta key on GA) reports `Wrong Plug-in`. Cluster and ClusterSet targets are not licensed targets.
- **Beta identity.** Auto-discovered beta targets are named with a " (Beta)" suffix so beta and GA deployments never collide in All Targets or notifications; beta-to-beta drops upgrade in place, beta-to-GA is a clean install.
- **Enterprise Manager 13.5 edition** (`13.5.9.N.0`) is built from the same source and available with the beta ([1.3](index.md#supported-mysql-versions-and-platforms)).
- **Numeric grid columns sort numerically** in the console (previously sorted as text, so 9 followed 10).
- **Config side-panel labels wrap at underscores** (`interactive_ | timeout`) instead of mid-word on the Performance chart pages, on both editions.

#### Security
- Process arguments are sanitised before they are logged: every ISO control character in a target-property value is replaced with `_`, width-preserving, so a value containing a line break can no longer forge log lines. Credentials never travelled in process arguments.
- Bundled third-party libraries updated to their current patch levels.

#### Upgrade notes
- The MySQL Database target type carries new metadata in this drop — the `License` metric group, and the licence check on every instance metric. Upgrading therefore needs the full deploy cycle in [3.4](install-and-upgrade.md#upgrading). Deploy the agent side in the same window as the OMS side; an agent left on the previous drop shows no `License` data and raises no licence incident.

## 10.1 Early Access build (2026-08-18)
The Early Access build: the first build of the plug-in put in front of customers, and the release this guide's feature scope describes.

#### Functionality Added or Changed
- Three target types: MySQL Database (`ip_mysql_database_beta`), MySQL Cluster (`ip_mysql_cluster_beta`) and MySQL ClusterSet (`ip_mysql_clusterset_beta`) — see [1.2](index.md#target-types).
- 104 metric groups on MySQL Database, 8 on MySQL Cluster and 3 on MySQL ClusterSet, including daily configuration snapshots that populate Enterprise Manager's configuration history and comparison ([chapter 6](metrics-reference.md#metrics-reference)).
- 21 console pages across the three target types, among them Query Analyzer, Query Analytics Trends, Backup, InnoDB Buffer Pool, the cluster Consensus, Messaging and Certification pages, and ClusterSet DR Health ([chapter 5](monitoring-pages.md#home-page-and-pages-tour)).
- 17 default metric thresholds ship set, plus an availability condition on each of the three target types, so a target alarms from the moment you add it ([7.1](alerts-and-thresholds.md#default-thresholds)).
- DR Promotion Ready alert on the MySQL ClusterSet target: CRITICAL when `dr_promotion_ready` stays below 1 for two consecutive 5-minute collections ([7.1](alerts-and-thresholds.md#default-thresholds)).
- Backup-source coverage alert on the MySQL Cluster target: a warning when the member the most recent successful backup was taken from is no longer online in the group (`BackupSource : source_offline`).
- MySQL Framework compliance content: 5 standards and 65 rules, ready to associate with no rule authoring ([chapter 9](compliance-rules.md#compliance-standards)).
- Run EXPLAIN job: capture an execution plan for a statement against a monitored MySQL Database target from the console ([8.1](jobs.md#run-explain)).
- TLS Mode `required` fails closed — a session that cannot be encrypted fails with an explicit error and the target goes Down rather than falling back to plaintext ([2.5](prerequisites.md#tls)).
- Unix-socket connections for a local agent, and a Kerberos configuration-file property on all three target types ([2.6](prerequisites.md#unix-socket-connections), 4.1).
- Autodiscovery of MySQL server instances on any host whose agent has the plug-in deployed ([4.4](targets-and-properties.md#autodiscovery)).
- Import through Self Update, then deploy to the OMS and to agents with the standard Enterprise Manager flow ([chapter 3](install-and-upgrade.md#installing-the-plug-in)).
- An Enterprise Manager 13.5 edition of this build, built from the same source as the EM 24ai edition, is certified in this beta ([1.3](index.md#supported-mysql-versions-and-platforms)).

#### Bugs Fixed
- Unix-socket authentication: the junixsocket native libraries are now packaged, so socket connections no longer fail with UnsatisfiedLinkError. Socket targets connect.
- Metric cache files and their lock files are now created with owner-only (0600) permissions, and cached objects are restored through a deserialization allow-list.
- ClusterSet health no longer reports an error when a replication channel is in the `CONNECTING` state during a normal reconnect.
- Configuration side panels display column names in their intended case, and long values wrap instead of being clipped.
- All three target types moved to new metadata in this build. Upgrading therefore needs the full deploy cycle in [3.4](install-and-upgrade.md#upgrading) — deploy to the OMS, restart the OMS, then deploy to agents — or the new content is stored without being activated.

#### Known limitations and boundaries
- **TLS verify modes are not available in this release.** The client truststore properties that `verify_ca` and `verify_identity` depend on are deferred, so those two modes are absent from the target pages and from EM CLI. `required` and `disabled` are the modes to use; `required` is proven to fail closed rather than downgrade, and certificate or identity checking is not part of this release ([2.5](prerequisites.md#tls)).
- **MySQL ClusterSet targets need MySQL Shell on the agent host.** Without `mysqlsh` the target degrades to a repository rollup that reports `fallback_reason MYSQLSH_NOT_FOUND`. A rollup cannot assess ClusterSet-wide promotion readiness, so `dr_promotion_ready` reads 0 and the DR Promotion Ready alert raises CRITICAL until MySQL Shell is installed ([2.2](prerequisites.md#mysql-shell-for-clusterset-targets)).
- **Query Analytics freshness on idle servers.** Like all Enterprise Manager keyed metrics, the query-digest groups retain their last collected rows when a collection window sees no new activity; read the `active_digest_count` column as the freshness signal. The statement-digest overflow row (`DIGEST IS NULL`), which the server uses once its digest table is full, is handled and does not appear as a statement.
- **Backup failure detection is asymmetric between tools.** MySQL Enterprise Backup writes a history row when a run fails; Percona XtraBackup writes nothing, so on XtraBackup-only estates backup age is the failure signal ([2.7](prerequisites.md#backup-tool-visibility)).
- **Backup detection depends on the history tables being readable.** A server with no history table for a tool is reported as that tool not detected, with no alert raised. Give the monitoring account read access to the history tables of every backup tool you actually run, or that tool reads as absent rather than as a problem ([2.7](prerequisites.md#backup-tool-visibility)).
- **ClusterSet health was exercised against MySQL 9.5 commercial.** DR readiness is gated on heartbeat freshness rather than on the replication channel state, so a channel that is reconnecting (`CONNECTING`) does not by itself change DR readiness.
- **InnoDB ClusterSet is validated on MySQL 9.5 commercial; an 8.4 ClusterSet is not yet certified.** InnoDB Cluster (Group Replication) is certified on 8.4. See the matrix in [1.3](index.md#supported-mysql-versions-and-platforms).
- **The replication metric group reports two different boolean vocabularies:** `replica_io_running` returns `Yes` or `No` while `replica_sql_running` returns `true` or `false`, so a custom threshold, compliance rule or script that reads both columns must not assume a single format ([7.1](alerts-and-thresholds.md#default-thresholds)).
- **The default thresholds are starting points, not tuning.** All 17 were verified as present on freshly created targets in our lab, sized for lab workloads; review them against your own service levels before you rely on them ([7.2](alerts-and-thresholds.md#changing-thresholds)).
- **Unix-socket connections are new in this build.** A target that has both **Host** and **Unix Socket Path** set connects over TCP ([2.6](prerequisites.md#unix-socket-connections)).
- **RDS, Aurora and Cloud SQL are supported by manual target add, not certified.** Managed services expose a subset of the underlying server, so individual metric groups may report collection errors.
- **Enterprise Manager 13.5 is certified in this beta.** Collection and compliance are certified on 13.5 in our lab, and the console's home and chart pages were verified on `13.5.9.9.0` (2026-08-25); the remaining console pages have not been individually walked on 13.5, so treat 24ai as the reference platform and report any 13.5 rendering difference you see.
- **An in-place upgrade keeps your targets.** Upgrading from one build to the next carries every target, its monitoring properties and any threshold you customized forward, and collection resumes. Where a build moves target metadata, the OMS restart in the middle of the cycle is what activates it — follow the procedure in [3.4](install-and-upgrade.md#upgrading) in full, and report anything that does not behave as it describes ([1.4](index.md#beta-status)).
- **MySQL versions outside the matrix are not blocked, only uncertified.** A newer server than 1.3 lists is expected to work; if an uncertified version misbehaves, the affected metric group degrades to a collection error on that group rather than taking the target down.
