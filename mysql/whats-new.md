---
title: What's new
nav_order: 1
---

# Release notes

**Topics:** 10.3 Open Beta drop 10 (2026-09-16) · 10.2 Open Beta drop 9 (2026-09-01) · 10.1 Early Access build (2026-08-18)

## 10.3 Open Beta drop 10 (2026-09-16)

The second Open Beta drop, plug-in `ip.em.xmyb`, builds `24.1.9.N.0` (EM 24ai) and `13.5.9.N.0` (EM 13.5) with N = 10. No customer received drop 9, so this is the first drop anyone installs, and it installs fresh ([3.1](install-and-upgrade.md#import-with-self-update) to 3.3); [upgrade notes](upgrade-notes.md) lists the operator actions in this drop, and the biggest of them comes first here. Both editions are built from the same commit; the exact versions are in `build-info.txt` beside the artifacts.

#### Functionality Added or Changed
- **MySQL Connector/J is no longer bundled with the plug-in.** From this drop the MySQL JDBC driver is customer-supplied: you download MySQL Connector/J and place one `mysql-connector-j-*.jar` in `<agentStateDir>/ip_plugin/<plug-in id>/lib` on every agent host that monitors MySQL targets (`ip_plugin/xmyb/lib` for the beta plug-in `ip.em.xmyb`, `ip_plugin/xmyb/lib` for the GA plug-in). Every collection and the Run EXPLAIN job load the driver from there through a launcher on the agent, there is no bundled fallback, and a collection on an agent without the driver fails with an error that names the directory the launcher looked in. The requirement, the supported versions and the install steps are in the prerequisite section *MySQL Connector/J on agent hosts* in [chapter 2](prerequisites.md#prerequisites). Place the driver before this drop is deployed to the agent.
- **Run EXPLAIN uses the customer-supplied driver.** The **MySQL - Run Explain Plan** job type (version 1.4) starts the plug-in through the same launcher the collections use, so it needs the driver readable by the job's host credential; a missing driver ends the step with one error line naming the directory ([8.1](jobs.md#run-explain)).
- **Endpoint lists for MySQL Cluster and MySQL ClusterSet targets.** `(Router) Host` and `(Router) Port` accept comma-separated lists; the JDBC connection and the MySQL Shell session try the list in order, so a container target no longer goes Down because its one configured member is unreachable ([4.1](targets-and-properties.md#target-properties), 2.3).
- **MySQL Router endpoints proven for both container types.** A Router port works for a MySQL Cluster target and, with password authentication, for a MySQL ClusterSet target on both the JDBC and the MySQL Shell path (`health_source` reads `ADMINAPI` behind a Router); list two Routers to survive losing one. Kerberos does not pass through Router ([4.1](targets-and-properties.md#target-properties), 4.3).
- **Kerberos on the ClusterSet Shell path.** With a Kerberos Configuration File on the target, MySQL Shell authenticates with the agent user's ticket and no password; `KERBEROS_TICKET`, `KERBEROS_NOT_SUPPORTED`, `KERBEROS_CLIENT_UNAVAILABLE` and `KERBEROS_CONFIG_UNREADABLE` name what is missing ([2.2](prerequisites.md#mysql-shell-for-clusterset-targets)).
- **Top Waits page** on the MySQL Database target: wait time by class and by event over a 24 Hours, Week or Month window, built from `WaitProfile` history, with socket waits excluded from the rankings and totalled separately ([5.1](monitoring-pages.md#mysql-database-pages)).
- **Two default thresholds on the wait metrics**: `WaitProfile.avg_wait_us` (WARNING 1 s, CRITICAL 5 s, three consecutive collections) and `WaitProfileSummary.top_wait_class` (WARNING when `lock` leads for five collections), taking the shipped count from 19 to **21** ([7.1](alerts-and-thresholds.md#default-thresholds)). The MySQL Database target metadata moves with them (see Upgrade notes below).
- **Effective privileges in the security snapshot.** `SecurityAccounts` now counts privileges an account holds through granted roles (at any depth, and `mandatory_roles`) and honours partial revokes on the `mysql` schema, so the seven account-privilege rules in the MySQL Security Standard evaluate what an account can actually do; their advice now includes the role path ([chapter 9](compliance-rules.md#compliance-standards)). MySQL 5.7 keeps a direct-only result.
- **Bulk onboarding and migration**: `mysql-onboard.sh` exports an estate to CSV, creates the targets with EM CLI, verifies Up and licence, associates the five standards and retires the sources on request, for greenfield estates and for moving off the Oracle MySQL plug-in or the beta ([4.7](targets-and-properties.md#bulk-onboarding-and-migration) and the [migration chapter](migration-from-omys.md)).
- **Amazon RDS for MySQL 8.4 is certified** (RDS MySQL 8.4.11): every metric group collects with the standard monitoring user; the managed-service differences are documented as expected behaviour ([1.3](index.md#supported-mysql-versions-and-platforms), 4.4).
- **Sizing and capacity guidance**: the measured per-target cost, the agent-host rule, which collection schedules to lower in a large estate, and the overload symptoms and their relief ([2.8](prerequisites.md#sizing-and-capacity)).
- **Query Analytics Trends Week and Month totals** are now scaled from the hourly and daily rollups they are served from, as Top Waits is, instead of summing averaged samples; the page and 5.1 say what is exact and what is an estimate.

#### Bugs Fixed
- **Socket targets no longer need a human login after a `mysqld` restart.** A `caching_sha2_password` account over a Unix socket authenticates on its own; a socket target used to go Down after every restart (or `FLUSH PRIVILEGES`) until someone logged in by another path ([2.6](prerequisites.md#unix-socket-connections)).
- **ClusterSet health names an unreachable member.** When the agent host reaches one listed endpoint but not another online member, `fallback_reason` now reads `MEMBER_UNREACHABLE` with its remedy, instead of `PARSE_FAILED`; a listed endpoint that is not part of a ClusterSet no longer stops the endpoint loop; and the MySQL Shell budget reserves time for the AdminAPI's member fan-out, so a single-endpoint health check may take up to 60 seconds before reporting ([2.2](prerequisites.md#mysql-shell-for-clusterset-targets), 4.1).
- **Console regions no longer pushed off the page.** A layout rule stretched page content on Query Analyzer, Query Analytics Trends, Top Waits and Database File I/O, on both editions; and Week and Month rows on Top Waits read the wait class from the event name, since the rollups carry no class column.
- **Week and Month windows on Top Waits and Query Analytics Trends** are scaled by the window's own cadence when only one rolled-up sample exists (a newly added target), show nothing rather than a fabricated zero on an empty window, and clear stale rows when a fetch fails.
- **`mysql-onboard.sh` no longer passes the monitoring password on the `emcli` command line**, where any local account on the OMS host could read it from the process list for the duration of each call; it goes through an owner-only file instead. The licence key stays on the command line because EM CLI offers no file form for properties.

#### Security
- Every `Host` entry must be a hostname, an IPv4 address or a bracketed IPv6 literal and every `Port` a number from 1 to 65535, so a crafted target property can no longer rewrite the JDBC URL (drop the TLS mode, switch on driver options). See [upgrade notes](upgrade-notes.md).
- The onboarding script's password handling above (CWE-214).
- MySQL Connector/J is no longer distributed inside the plug-in; you supply and patch it on your own schedule.

#### Upgrade notes
- **Place MySQL Connector/J on every agent host before deploying this drop to its agents** (prerequisite section *MySQL Connector/J on agent hosts* in [chapter 2](prerequisites.md#prerequisites)). Once the agent is on this drop, nothing collects until the driver is in place.
- The MySQL Database target type carries new metadata in this drop (the two wait thresholds), so upgrading needs the full deploy cycle in [3.4](install-and-upgrade.md#upgrading): OMS first, let it restart, then the agents. Verify with `emcli get_threshold -target_name=<target> -target_type=ip_mysql_database_beta -metric_name=WaitProfileSummary`. The MySQL Cluster and MySQL ClusterSet target types are unchanged.
- Run EXPLAIN needs the agent side on this drop as well as the OMS side; between the two, the job fails on that agent ([8.1](jobs.md#run-explain)).
- Security Standard results can change after the first configuration snapshot on this drop, because the privilege rules now see role-granted privileges (see [upgrade notes](upgrade-notes.md)).
- A notification rule or script keyed on `fallback_reason` should add `MEMBER_UNREACHABLE` (see [upgrade notes](upgrade-notes.md)).

#### Known limitations and boundaries
- **`top_wait_class = lock` means table and metadata locks.** InnoDB charges a row-lock wait to `wait/io/table/sql/handler`, class `io`, so row-lock contention does not show as `lock` on this signal; use the InnoDB Row Lock Waits page for it. The `wait/synch/*` instruments are disabled by default, so `synch` does not lead until you enable them ([7.1](alerts-and-thresholds.md#default-thresholds)).
- **Week and Month windows on Top Waits and Query Analytics Trends are estimates.** They are served from Enterprise Manager's hourly and daily rollups and scaled by the sample span; the 24 Hours window is exact ([5.1](monitoring-pages.md#mysql-database-pages)). Windows also trail the repository's daily rollup job, so they can be empty for the first day after a target is added.
- **Every boundary listed under 10.1 still applies** unless a bullet above says otherwise; in particular the TLS verify modes remain unavailable, and InnoDB ClusterSet remains validated on MySQL 9.5 commercial.

## 10.2 Open Beta drop 9 (2026-09-01)

The Open Beta drop. It is a **separate plug-in** from the Early Access build below and from the GA release to come (`ip.em.xmyb`, target types `ip_mysql_database_beta`, `ip_mysql_cluster_beta`, `ip_mysql_clusterset_beta`); see [the Open Beta notice](beta-pre-release.md) for the terms of use and the install path, and [upgrade notes](upgrade-notes.md) for operator actions. Both editions are built from the same commit; the exact versions are in `build-info.txt` beside the artifacts.

#### Functionality Added or Changed
- **Licensing.** Every MySQL Database target carries a **License Key** property ([4.1](targets-and-properties.md#target-properties)) and a `License` metric group (status, licensed, days remaining, expiration, type, instances, customer), collected on the agent every 15 minutes and again whenever the key changes. Two default thresholds ship with it — CRITICAL when the licence is not active, WARNING/CRITICAL at 30/7 days before expiry — taking the shipped threshold count from 17 to **19** ([7.1](alerts-and-thresholds.md#default-thresholds)). While the status is anything but `Active`, every other metric group on that target reports `Collection stopped by license status: …` until a valid key is entered; availability keeps reporting so the target stays Up. Keys are issued per plug-in: a GA key on the beta (or a beta key on GA) reports `Wrong Plug-in`. Cluster and ClusterSet targets are not licensed targets.
- **Beta identity.** Auto-discovered beta targets are named with a " (Beta)" suffix so beta and GA deployments never collide in All Targets or notifications; the procedure for moving between beta drops ships with each drop, beta-to-GA is a clean install.
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
- **Enterprise Manager 13.5 is certified in this beta.** Collection and compliance are certified on 13.5 in our lab, and the console's home and chart pages were verified on an internal 13.5 build (2026-08-25); the remaining console pages have not been individually walked on 13.5, so treat 24ai as the reference platform and report any 13.5 rendering difference you see.
- **An in-place upgrade keeps your targets.** Upgrading from one build to the next carries every target, its monitoring properties and any threshold you customized forward, and collection resumes. Where a build moves target metadata, the OMS restart in the middle of the cycle is what activates it — follow the procedure in [3.4](install-and-upgrade.md#upgrading) in full, and report anything that does not behave as it describes ([1.4](index.md#beta-status)).
- **MySQL versions outside the matrix are not blocked, only uncertified.** A newer server than 1.3 lists is expected to work; if an uncertified version misbehaves, the affected metric group degrades to a collection error on that group rather than taking the target down.
