---
title: Upgrade notes
nav_order: 4.5
---

# Upgrade Notes

Release notes for changes that need operator action beyond a routine deploy —
security remediation, target metadata that has to be activated, breaking column
changes. One section per drop, **newest first**.

Internal builds that were never shipped to a customer are not listed here.

## GA (24.1.9.x)

**Target metadata moves again (`META_VER`, from the last Open Beta drop: MySQL Database 2.8 to 3.3, MySQL Cluster 1.6 to 1.8, MySQL ClusterSet 1.4 to 1.7).**
This release changes units and labels on the three target types, adds columns, and changes a default threshold, all of which
are collection metadata. Deploy to the **OMS first, restart it, then the agents**; an agent-only deploy leaves the previously
activated collection in place while EM reports success. GA is a fresh install: the Open Beta is a different plug-in id, and
internal drops cannot be upgraded in place, so targets are created new at GA and get everything below from creation, with
nothing to do. What differs from the Open Beta drops:

- **Units.** Columns that carry a quantity now have their real Enterprise Manager unit (bytes, seconds, milliseconds,
  microseconds, hours, days, percent) instead of `NA`; plain counts, flags, coded settings and identifiers stay `NA`. Collected
  values are unchanged, so history and thresholds carry over, but a chart or report that formatted a column as a bare number
  may now show a unit.
- **Labels.** Labels now state what a flag's 1 means, what a coded column's values are, that `-1` means unknown or not
  assessed, whether a value is a `(setting)` or `(current)`, and the window a computed figure covers (user guide [6.3](metrics-reference.md#63-naming-conventions)). Status-counter groups
  are labelled `(cumulative since server start)`. Anything that matches a metric by its display label, rather than by its internal
  name, needs the new text; internal metric and column names are unchanged.
- **New columns.** Columns are added at the end of their groups, never reordered: an explicit "not available" flag beside
  every column that used to report a missing value as 0 (for example `backup_history_visible`, `never_expires`,
  `lag_measured`), and a real lock-wait age (`waiting_seconds`) on the InnoDB row lock group (from `INNODB_TRX.trx_wait_started`) and the time in the wait state on the metadata lock group (`PROCESSLIST_TIME`). Without the
  `PROCESS` privilege, which is in the documented grant set (user guide [2.4](prerequisites.md#24-the-monitoring-user)), every lock-wait age reads -1.
- **Monitoring Readiness metrics.** MySQL Database gains `readiness_detail`, a real-time-only metric the Monitoring Readiness
  page reads (it is probed live and never collected or stored), and `readiness_summary`, one row collected hourly that counts
  features by status for the Home page; MySQL ClusterSet gains `readiness_detail`. Neither carries an alert condition.
  Targets created at GA have them from creation; there is nothing to configure. The checks are read-only: the statement that
  would fix a check is shown on the page, and the plug-in never runs it.
- **Tables and Indexes metrics.** MySQL Database gains three groups, `TableStorage`, `IndexStorage` and `IndexSummary`, each
  collected hourly and kept as history, with no alert condition. `TableStorage` and `IndexStorage` hold the 500 largest tables
  and indexes plus one `/other/` row and one `/system/` row (the MySQL-owned schemas) so totals stay complete;
  `IndexSummary` is one row counting full-scan tables, unused indexes and redundant indexes from the sys schema. A size or
  count the server does not expose is blank, never 0: index sizes are InnoDB only, and each `IndexSummary` count is blank
  with a reason when the account cannot read its sys view or performance_schema table I/O is off. Targets created at GA have
  the groups from creation. Reading them uses the certified grant; the account must be able to read `information_schema`,
  `sys` and `mysql.innodb_index_stats` (`SELECT ON *.*` covers all three). On a server with very many tables the hourly
  read of `information_schema` is the cost to know about; MySQL 8 serves it from its statistics cache.
- **DR Promotion Ready does not fire on "not assessed".** `ClusterSetHealth.dr_promotion_ready` is CRITICAL on `EQ 0`
  only, and a ClusterSet target created at GA carries that condition from creation. A ClusterSet monitored without MySQL
  Shell, or where MySQL Shell could not be used, reports -1 (not assessed) and `health_status` `UNKNOWN` instead of a false 0.
  One consequence: a 0 to -1 transition clears a real DR CRITICAL. If readiness was failing (0) and MySQL Shell then becomes
  unusable, the incident clears although nothing was fixed. The clear message says only that no failure is being reported:
  check `health_status`. The `fallback_reason` WARNING (below) is what tells you MySQL Shell has broken.
- **New WARNING on `ClusterSetHealth.fallback_reason`.** New ClusterSet targets carry it from creation. It raises after two
  consecutive collections when MySQL Shell could not be used for a reason an operator can fix (`AUTH_FAILED`, `TIMEOUT`,
  `UNREACHABLE`, `MEMBER_UNREACHABLE`, `KERBEROS_TICKET`, `KERBEROS_CONFIG_UNREADABLE`, `TLS_TRUSTSTORE_REQUIRED`,
  `PARSE_FAILED`). It stays quiet for reasons that describe how the target is set up (`MYSQLSH_NOT_FOUND`,
  `SOCKET_CONNECTION`, `KERBEROS_NOT_SUPPORTED`, `KERBEROS_CLIENT_UNAVAILABLE`), and a target that is not part of a
  ClusterSet (`NOT_A_CLUSTERSET`) reports no row at all. Notification rules keyed on `fallback_reason` may want it.
- **Console-only descriptions.** Metric descriptions appear in the console and are not passed to an AI agent by Enterprise
  Manager's MCP server (user guide [6.3](metrics-reference.md#63-naming-conventions)), which is why the meaning now sits in the label.

**Last Seen removed from the three statement groups.** `SysStatementByLatency`, `SysStatementByExecCount` and
`SysStatementByFirstSeen` no longer carry `last_seen`, and the Query Analyzer grid no longer shows a Last Seen column. It was a
microsecond-timestamp string that changed on almost every collection, and it accounted for about 98% of this target type's rows
in the repository's string-history table (`EM_METRIC_STRING_HISTORY`). `first_seen` stays. This ships with the `META_VER` bump
of the same release, so deploy to the **OMS first, restart it, then the agents**.

**Collection connections open with the default schema `performance_schema`.** The plug-in's JDBC metric collections now
connect with `performance_schema` as their default schema, so the statements they run are recorded under it in the digest
tables and Home's Top SQL and Query Analyzer hide them by default (user guide [5.1](monitoring-pages.md#51-mysql-database-pages); a checkbox shows them again). The
certified grant (`SELECT, PROCESS, REPLICATION CLIENT ON *.*`, [Prerequisites](prerequisites.md#24-the-monitoring-user) section 3) already covers
it, so no grant changes. If the monitoring account cannot use the `performance_schema` database (a grant that does not
reach it) or the server has no such database, the plug-in connects with no default schema instead and its own statements
stay visible on both pages. It tries the schema again an hour later, and the agent's plug-in log warns once per target per
process and again at each hourly re-probe (more often while collections overlap). Sessions
the plug-in opens now show `performance_schema` as their schema in Database Processes. Statements the plug-in ran before
this release were recorded with no schema and stay visible until the digest table is reset
(`TRUNCATE TABLE performance_schema.events_statements_summary_by_digest`) or MySQL restarts. Query Analytics Trends
counts every statement, as before.

## Open Beta drop 10 (2026-09-16)

The second Open Beta drop. No customer received drop 9, so this is the first drop anyone installs: a first install
follows [chapter 3](install-and-upgrade.md#installing-the-plug-in) of the user guide, and the one entry below that applies to it is the Connector/J step. The rest
matters when you move to this drop from an earlier build.

**MySQL Database target metadata moves in this drop (`META_VER` 2.6 to 2.7).** Two default thresholds are added on the wait
metrics (user guide [7.1](alerts-and-thresholds.md#71-default-thresholds)): `WaitProfile.avg_wait_us` and `WaitProfileSummary.top_wait_class`. Because this is a collection-metadata
change, deploy to the **OMS first, restart it, then the agents** — an agent-only deploy leaves the previously activated collection
in place, and EM will report success while the new conditions never activate. Verify with
`emcli get_threshold -target_name=<target> -target_type=ip_mysql_database -metric_name=WaitProfileSummary` after the cycle.
Existing targets keep any thresholds an operator has already edited; the new ones apply to targets created after the upgrade.

*Known behaviour, by design:* `avg_wait_us` is a threshold on a keyed metric, so Enterprise Manager evaluates it per wait event
and can open one incident per event name. That is deliberate — the incident names the event that is stuck, which is the
actionable detail — but on a host with several slow devices it means several incidents rather than one.

### MySQL Connector/J is no longer bundled: place it on every agent host before deploying this drop to agents

The plug-in no longer carries the MySQL JDBC driver. Each agent host that monitors a MySQL target needs exactly one
`mysql-connector-j-*.jar` in `<agentStateDir>/ip_plugin/xmyb/lib/` (user guide [2.9](prerequisites.md#29-mysql-connectorj-on-agent-hosts): `emctl status agent` prints
`<agentStateDir>` as **Agent Home**; 8.4.0 is the tested version, SHA-256 in the guide). The directory is outside the
plug-in's own directories, so it survives upgrades and undeploys.

- **Order matters:** place the jar, then deploy this drop to the agent. An agent upgraded without it stops every MySQL
  collection it runs with `MySQL Connector/J not found: no mysql-connector-j-*.jar in ... Place exactly one Connector/J
  jar there.` until the jar is in place; collection resumes on the next cycle, nothing needs restarting.
- **Run EXPLAIN** (job type `MySQL - Run Explain Plan`, now version 1.4) runs through the same launcher and reads the same
  directory. Its Host Preferred Credential must run as a user that can read the jar and the plug-in's scripts directory,
  and when it switches user through `sudo` it must keep the agent's environment: `env_reset` without `env_keep` fails the
  job with `EMSTATE is not set in the job step`. Upgrade the agents in the same window as the OMS: the job type is
  OMS-side metadata, so with the OMS upgraded and an agent still on an earlier drop, Run EXPLAIN against that agent's
  targets fails with Perl's "Can't open perl script" until the agent is upgraded.
- The job step never creates the driver directory; the agent's collections do, as the agent owner, or you create it as
  in the guide.

### Socket targets no longer need a human login after a mysqld restart

A socket target used to be able to go Down after every `mysqld` restart (or `FLUSH PRIVILEGES`) and stay Down until something else logged into the monitoring account by another path — MySQL treats a Unix-socket connection as already secure and expects a cleartext password during `caching_sha2_password` full authentication, but the driver only sent the password that way inside TLS, so it sent an RSA-encrypted form that the server rejected on a socket every time.

Now, a socket connection loads a socket-aware `caching_sha2_password` client plug-in (`authenticationPlugins`, replacing the driver's built-in one for socket connections only) that sends the cleartext password over the socket the same way the driver already does inside TLS. Full authentication completes on its own after a restart — no TLS involved, no operator action, and TLS Mode's meaning is unchanged (user guide 2.5/2.6). **No operator action** — with one exception: a socket target whose Unix Socket Path is a proxy listener (MySQL Router `socket=`, ProxySQL) rather than `mysqld`'s own socket must be repointed at the proxy's TCP port, because the server does not treat a proxied socket as a secure transport (user guide [2.6](prerequisites.md#26-unix-socket-connections)).

### Cluster and ClusterSet targets accept endpoint lists

`(Router) Host` and `(Router) Port` on both container types now accept comma-separated lists (user guide [4.1](targets-and-properties.md#41-target-properties)). No target metadata changed, so an agent-side deploy is sufficient and existing single-endpoint targets are unaffected. **No operator action.**

### ClusterSet health names an unreachable member: new `fallback_reason` value `MEMBER_UNREACHABLE`

A ClusterSet target whose agent host could reach one listed endpoint but not another member that Group Replication still
considered online used to fall back with `fallback_reason` `PARSE_FAILED` (or `TIMEOUT` once several members were
unreachable), which pointed at the wrong remedy. It now reports **`MEMBER_UNREACHABLE`**, with the remedy in user guide [2.2](prerequisites.md#22-mysql-shell-for-clusterset-targets):
open a path from the agent host to every member of every cluster on its MySQL port, not only to the members listed on the
target. Two related changes ship in the same fix: a listed endpoint that is not part of a ClusterSet no longer stops the
endpoint loop (the next endpoint is tried, and `NOT_A_CLUSTERSET` is reported only when every endpoint says so), and the
MySQL Shell process budget now reserves time for the AdminAPI's status fan-out to every member, so a single-endpoint health
check can take up to 60 seconds rather than 30 before it reports (user guide [4.1](targets-and-properties.md#41-target-properties)). No target metadata changed; an agent-side
deploy is sufficient. **Operator action only if you match on `fallback_reason`:** an incident rule, notification or script
that keyed on `PARSE_FAILED` or `TIMEOUT` to catch an unreachable member should add `MEMBER_UNREACHABLE`.

### Compliance results change: the privilege rules now see role-granted privileges

The `SecurityAccounts` configuration snapshot now reports **effective** privileges. Every `has_*` privilege flag counts the
account's own grants plus every role it can reach (roles granted to it, at any nesting depth, and the server's
`mandatory_roles`), and `has_mysql_schema_write` honours partial revokes on the `mysql` schema. The seven account-privilege
rules in the MySQL Security Standard (Over-Privileged Accounts, Accounts With Grant Option, Accounts With File Privilege,
Accounts With Process Privilege, Accounts With Shutdown Privilege, Accounts With Super Privilege, Accounts With MySQL Schema
Write Access) evaluate those flags, so after the first configuration snapshot on this drop (24-hour schedule, user guide [9.2](compliance-rules.md#92-associating-standards-and-reading-results))
they can report violations for accounts that hold a privilege only through a role, and a target's Security Standard score
can drop without anything having changed on the server. The rules' advice now includes the role path (`SHOW GRANTS FOR ...
USING ...`; revoke the role, or strip the privilege from the role). MySQL 5.7 has no roles and keeps a direct-only result of
the same shape. No new columns and no target metadata change, so an agent-side deploy is sufficient. **Operator action:**
review new Security Standard violations after the first snapshot as findings rather than regressions. Roles are still listed
as accounts in the snapshot, as before.

### JDBC URL injection remediation (security)

The plug-in built its JDBC connection URL by concatenating the target's `Host`
and `Port` properties as it received them. Those values are controlled by the
target definition, so a `?`, `/` or `#` in one of them ended the host part of
the URL early and let the rest of the value be read as driver properties: the
`sslMode` and timeouts the plug-in sets could be dropped (a TLS downgrade), and
driver options such as `allowLoadLocalInfile` or `autoDeserialize` could be
switched on. Every `Host` entry must now be a hostname, an IPv4 address or a
bracketed IPv6 literal; every `Port` entry a number from 1 to 65535; a list may
hold at most 16 entries. An entry that fails the rule stops the connection with
a message that does not echo the value.

- No operator action beyond upgrading. A target whose `Host` or `Port` already
  carried such a character was never connecting to the server it named; it now
  reports the rejection instead of connecting somewhere else.
- Redirecting a target to another server was always available to anyone allowed
  to edit its properties. This fix removes what a crafted value could add on
  top: the TLS downgrade and the driver options.
- The two DEBUG lines introduced with endpoint lists pass through the same
  control-character sanitizer as the process arguments (previous entry below).

## Open Beta drop 9 (2026-09-01)

The first drop of the Open Beta. If this is your first install there is nothing
to do on this page — follow [chapter 3](install-and-upgrade.md#installing-the-plug-in) of the user guide instead. What follows
matters when you move to this drop from an earlier one.

### Licence enforcement: a MySQL Database target without an Active licence stops collecting

From this drop every MySQL Database target needs a valid licence key in
its **License Key** property (guide [4.1](targets-and-properties.md#41-target-properties)). While the `License` metric's status
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

### This drop moves the MySQL Database target metadata

Licensing adds the `License` metric group, its collection item and two default
thresholds to the MySQL Database target type, and the licence check adds its
properties to every instance metric. Enterprise Manager activates target-type
metadata on the OMS side, so this drop needs the full cycle — **deploy to the
OMS → let the OMS restart → deploy to agents** — rather than an agent-only
deploy. Skipping the restart does not fail the deploy: every step can report
Success while Enterprise Manager keeps the previous metadata active.

An agent left on the previous drop carries no `License` metric at all: the group
shows no data and its `licensed` / `days_remaining` incidents never raise. Deploy
the agent side in the same maintenance window as the OMS side (guide [3.4](install-and-upgrade.md#34-upgrading)).

Verify afterwards, against the beta target type:

```
emcli get_threshold -target_name="<database target>" -target_type=ip_mysql_database_beta
```

The `License` conditions — `licensed` and `days_remaining` — must be listed. If
they are not, the metadata was stored but not activated: repeat the OMS deploy,
let the restart finish, and redeploy to the agents.

The MySQL Cluster and MySQL ClusterSet target types are unchanged in this drop.
Chapter [3.4](install-and-upgrade.md#34-upgrading) of the user guide remains the authoritative upgrade procedure.

### Log injection remediation (security)

The plug-in logged its process arguments as it received them. Those arguments
carry target-property values that the target definition controls — host, socket
path, Kerberos configuration file — so a carriage return or line feed in one of
them could forge whole log lines, and an escape character could inject terminal
escape sequences into anything reading the agent log. Every ISO control character
is now replaced with `_`, width-preserving, so the substitution is visible rather
than silent.

- No operator action beyond upgrading.
- Credentials were never among those arguments: they travel by environment
  variable on the metric path and by stdin on the job path.
- Bundled third-party libraries are updated to their current patch levels.
