---
title: Upgrade notes
nav_order: 4.5
---

# Upgrade Notes

Release notes for changes that need operator action beyond a routine deploy —
security remediation, metadata-version bumps, breaking column changes. One
section per release, **newest first**.

## Unreleased (since the 24.1.9.75.0 beta)

### Licence enforcement: a MySQL Database target without an Active licence stops collecting

From this release every MySQL Database target needs a valid licence key in
its **License Key** property (guide 4.1). While the `License` metric's status
is anything but `Active`, **every other metric group on that target reports a
collection error** (`Collection stopped by license status: …`) — each group at
its own interval, so an unkeyed target shows roughly a hundred metric
collection errors within a day, not one — and the target raises a CRITICAL
incident. Availability (`Response`) keeps reporting, so the target stays Up.
Configuration snapshots stop with the rest, so configuration history and
compliance scoring reflect the last snapshot taken while licensed (or nothing,
for a new target) until a key is accepted. Collections resume at their next
interval once a key is accepted. Cluster and ClusterSet targets are not
licensed targets and are unaffected. **Action: have the licence keys to hand
and enter them on every MySQL Database target as soon as its agent is
upgraded** — keys can be set before the upgrade (the property is ignored by
older drops), which avoids the error burst entirely.

### Upgrading from 24.1.9.75.0 to this release moves the MySQL Database metadata (`META_VER` 2.4 → 2.6)

Licensing adds the `License` metric group, its collection item and two default
thresholds to the MySQL Database target type, and licence enforcement adds the
gate's environment properties to every Instance metric, so that type's
`META_VER` moves from 2.4 to 2.6 in this release. Agents still on 75.0 carry no `License`
metric: on such an agent the group shows no data and its `licensed` /
`days_remaining` incidents never raise, so upgrade the agent-side plug-in in
the same maintenance window as the server side (guide 3.4). The MySQL Cluster
and MySQL ClusterSet types are unchanged.

The earlier statement in this section — that no `META_VER` moved after 75.0
and the 75.0 → next step needed no metadata cycle — was true up to the
licensing change and is withdrawn by it. `plugin.xml` still declares agent-side
compatibility with `24.1.9.75.0`; that declaration is only valid while no
`META_VER` moves between the two versions, so it must be re-decided before the
next GA-identity release (release checklist, Phase 2).

Chapter 3.4 of the user guide remains the authoritative upgrade procedure.

### Log injection remediation (security)

The plugin logged its raw process arguments. Argv carries target-property values
that the target definition controls — host, socket path, Kerberos configuration
file — so a CR or LF in one of those could forge whole log lines, and an ESC
could inject terminal escape sequences into anything reading the agent log. Every
ISO control character is now replaced with `_`, width-preserving so the
substitution is visible rather than silent.

- No operator action beyond upgrading.
- Credentials were never in argv: they travel by environment variable on the
  metric path and by stdin on the job path.
- Log4j moves 2.24.3 to 2.25.5.

## 24.1.9.75.0 (Beta)

The beta release. Everything below shipped in it.

### Deploy: full restart cycle required (`ip_mysql_clusterset` `META_VER` `1.2` → `1.3`, DR promotion alert)

The ClusterSet DR readiness alert adds a `<Condition>` on `dr_promotion_ready`
to `ip_mysql_clusterset`. Same activation rule as every bump in this section:
**deploy to server → OMS restart → deploy to agents**, or the Condition ships
stored-but-not-activated while every step reports Success. Verify after
upgrading: `emcli get_threshold -target_name=<clusterset>
-target_type=ip_mysql_clusterset` must list it.

- **Expect this alert to fire, and keep firing, on any agent host without MySQL
  Shell.** Without `mysqlsh` the ClusterSet health metric falls back to a
  repository-only rollup, and that fallback reports `dr_promotion_ready = 0`
  because it cannot establish promotion readiness — not because readiness is
  known to be false. Install MySQL Shell on the agent host that monitors the
  ClusterSet, or expect a standing CRITICAL that no ClusterSet state will clear.

### Agent JVM command line changed (`ip_mysql_database` `META_VER` `2.3` → `2.4`, `ip_mysql_cluster` `1.4` → `1.5`)

The cache-hardening bundle changes the agent-side command for all three target
types, adding a heap cap and a deserialization filter:

```
-Xmx512m -Djdk.serialFilter=maxarray=100000;maxrefs=200000;maxdepth=20;maxbytes=10485760
```

The filter bounds what the on-disk metric cache will deserialize. Two of the
three types carry `META_VER` bumps alongside it, so the full restart cycle
applies — **deploy to server → OMS restart → deploy to agents**.

- The collector JVM is now capped at 512 MB where it previously had the agent's
  default. If a collector dies on heap after upgrading, report it rather than
  raising the cap locally — the cap is deliberate.


### Deploy: full restart cycle required (`ip_mysql_cluster` `META_VER` `1.3` → `1.4`, backup-source health)

The backup-source health alert adds the `BackupSource` metric
and its warning-only `source_offline` `<Condition>` to `ip_mysql_cluster`.
Same activation rule as every metadata bump below: **deploy to server → OMS
restart → deploy to agents**, or the Condition ships stored-but-not-activated
while every check reports Success (the exact failure lab-proven at
24.1.9.62.0, below). Verify after upgrading: `emcli get_threshold
-target_name=<cluster> -target_type=ip_mysql_cluster` must list
`BackupSource : source_offline` (warning `0`, Every 15 Minutes). The cluster
monitoring credential must be able to `SELECT` `mysql.backup_history` (and
`PERCONA_SCHEMA.xtrabackup_history` where present) — without it the metric
degrades to silent with a `WARN` in the agent log.

### Deploy: full restart cycle required (`META_VER` bumps on BOTH types, F-09 advisor pack)

The F-09 advisor pack adds two CONFIG metrics to `ip_mysql_database`
(`SecurityAccounts` → ECM table `MYS_DB_SEC_ACCTS`, the plugin's first KEYED
config table — key `USER_HOST`, built injectively in the collector;
`SecurityConfigExt` → `MYS_DB_SEC_CFG`) and 35 compliance rules. TWO target
types carry metadata-version bumps, and BOTH need the full restart-cycle
deploy — **deploy to server → OMS restart → deploy to agents**:

- **`ip_mysql_database` `META_VER` `2.1` → `2.2`** — **lab-proven necessary
  on 24.1.9.59.0 (2026-08-07): deploying the new metadata WITHOUT the bump
  made the OMS silently skip both the new ECM table DDL and the
  compliance-content re-import** (deploy reports Success throughout;
  `all_tables`/`MGMT$COMPLIANCE_STANDARD_RULE` show nothing landed).
- **`ip_mysql_cluster` `META_VER` `1.2` → `1.3`** — activates the three Gr
  threshold `<Condition>`s (applier queue, certification queue, consensus
  latency). **Lab-proven necessary on 24.1.9.62.0 (2026-08-08): without the
  cluster bump the Conditions ship stored-but-not-activated** — deploy
  reports Success, `verify_types` passes, yet `emcli get_threshold` on the
  cluster target returns nothing and no threshold alert can ever fire.
  Verify after upgrading: `emcli get_threshold -target_name=<cluster>
  -target_type=ip_mysql_cluster` must list all three Conditions.

### Deploy: full restart cycle required again (`META_VER` 2.2 → 2.3, config side-panels)

The five Performance chart pages gain their config side-panels, fed by six
REALTIME-only RAW mirrors of the config groups (`ConnectionLive` …
`TableConfigurationLive`) — target-XML metadata only, no new collections, no
repository storage. The `META_VER` move needs the standard full cycle:
deploy to server → OMS restart → deploy to agents. Verify: the five pages
render their right-hand config panels with live values.

### `innodb_log_capacity_used` now reports checkpoint age (value-semantics fix)

Before this release the InnoDB Log metric's `innodb_log_capacity_used` echoed
the server's "Log capacity used" line, which reports the **pre-allocated redo
file footprint** — a value that always equals `innodb_log_capacity` and never
moves. From this release the column is derived as **checkpoint age** (log
sequence number minus last checkpoint): the bytes of redo that crash recovery
would replay, i.e. the redo usage the column's name promises, the number to
watch against capacity.

- **Expect the value to drop** from the constant capacity figure (e.g.
  104857600) to a small, varying number on healthy instances. History drawn
  across the upgrade will show a cliff; that is the fix, not a regression.
- Any custom threshold an operator placed on this column against the old
  constant value should be reviewed (a threshold below capacity would have
  been permanently in violation before; a meaningful one can now be set).
- On servers without redo-capacity lines (pre-8.0.30), the column now
  populates (it previously did not) — derived from the LSNs, which all
  supported versions print. Absent only if either LSN line is missing.

## 24.1.9.26.0

### `report_password` remediation (security)

This release stops the plugin collecting the MySQL global variable
`report_password` — a replica's replication password — in the `ReplicationReplica`
metric (F-02). **It does not remove values already collected.**

- `ReplicationReplica` runs **hourly** (`opar/resources/collection/ip_mysql_database.xml`),
  so any deployment that was running the older plugin has been writing roughly
  24 rows/day of that password, in cleartext, into `MGMT_METRICS_RAW`, plus the
  hourly and daily rollups, for as long as it was monitoring a replica with
  `report-password` configured.
- That history persists until the EM repository's retention window elapses —
  typically 7 days raw / 31 days hourly / 365 days daily by EM default, but
  **retention is configurable per repository**, so check the actual setting
  rather than assuming the default. Until it expires, any EM admin can read the
  password out of `mgmt$metric_details` for that target.
- **Purge the collected `ReplicationReplica` `report_password` history** rather
  than wait out retention. The exact purge procedure depends on EM repository
  version, so use Oracle's documented metric-data purge / retention tooling for
  your EM release (or raise it with Oracle Support) rather than a generic
  command — this is not something to improvise against `MGMT_*` tables directly.
- **Rotate the replication password on every replica this was collected from,
  in addition to purging.** Purging removes EM's copy; it does not undo the
  exposure — the value was already readable by every EM admin for the retention
  window before the purge runs.
- Scope: the value transits the monitoring agent's JVM during collection, but
  this plugin never wrote it to agent logs. After upgrading, it is no longer
  collected, emitted, or persisted anywhere by the plugin.

### Deploy: full restart cycle required (`META_VER` 1.6 → 1.7)

This release bumps `ip_mysql_database` target metadata `META_VER` from `1.6` to
`1.7` (the `report_password` `ColumnDescriptor` is removed from
`opar/resources/target/ip_mysql_database.xml`, among other changes). EM keys
target-type **activation** on `(target_type, META_VER)`, so this needs the full
restart-cycle deploy — **deploy to server → OMS restart → deploy to agents** —
not a warm redeploy.

- **Known hazard:** skipping the OMS restart doesn't fail the deploy — it can
  report "Register metadata: Success" while EM silently keeps the *previous*
  metadata version active (`EM_TARGET_TYPES_E` never gets the new row). Verify
  the active version after upgrading, e.g. `emcli get_target_types`, and confirm
  `ip_mysql_database` is live at `META_VER 1.7` before treating the upgrade as
  done.
- Dropping the `report_password` column leaves existing historical rows with
  the old (36-column) shape — that's expected, not a data-integrity problem. The
  remaining columns keep collecting normally on the next cycle; no data
  migration is required or provided.
