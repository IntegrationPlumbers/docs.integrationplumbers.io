---
title: Upgrade notes
nav_order: 4.5
---

# Upgrade Notes

Release notes for changes that need operator action beyond a routine deploy —
security remediation, target metadata that has to be activated, breaking column
changes. One section per drop, **newest first**.

Internal builds that were never shipped to a customer are not listed here.

## Open Beta drop 10 (2026-09-16)

The second Open Beta drop. No customer received drop 9, so this is the first drop anyone installs: a first install
follows [chapter 3](install-and-upgrade.md#installing-the-plug-in) of the user guide, and the one entry below that applies to it is the Connector/J step. The rest
matters when you move to this drop from an earlier build.

**MySQL Database target metadata moves in this drop (`META_VER` 2.6 to 2.7).** Two default thresholds are added on the wait
metrics (user guide [7.1](alerts-and-thresholds.md#default-thresholds)): `WaitProfile.avg_wait_us` and `WaitProfileSummary.top_wait_class`. Because this is a collection-metadata
change, deploy to the **OMS first, restart it, then the agents** — an agent-only deploy leaves the previously activated collection
in place, and EM will report success while the new conditions never activate. Verify with
`emcli get_threshold -target_name=<target> -target_type=ip_mysql_database -metric_name=WaitProfileSummary` after the cycle.
Existing targets keep any thresholds an operator has already edited; the new ones apply to targets created after the upgrade.

*Known behaviour, by design:* `avg_wait_us` is a threshold on a keyed metric, so Enterprise Manager evaluates it per wait event
and can open one incident per event name. That is deliberate — the incident names the event that is stuck, which is the
actionable detail — but on a host with several slow devices it means several incidents rather than one.

### MySQL Connector/J is no longer bundled: place it on every agent host before deploying this drop to agents

The plug-in no longer carries the MySQL JDBC driver. Each agent host that monitors a MySQL target needs exactly one
`mysql-connector-j-*.jar` in `<agentStateDir>/ip_plugin/xmyb/lib/` (user guide [2.9](prerequisites.md#mysql-connectorj-on-agent-hosts): `emctl status agent` prints
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

Now, a socket connection loads a socket-aware `caching_sha2_password` client plug-in (`authenticationPlugins`, replacing the driver's built-in one for socket connections only) that sends the cleartext password over the socket the same way the driver already does inside TLS. Full authentication completes on its own after a restart — no TLS involved, no operator action, and TLS Mode's meaning is unchanged (user guide 2.5/2.6). **No operator action** — with one exception: a socket target whose Unix Socket Path is a proxy listener (MySQL Router `socket=`, ProxySQL) rather than `mysqld`'s own socket must be repointed at the proxy's TCP port, because the server does not treat a proxied socket as a secure transport (user guide [2.6](prerequisites.md#unix-socket-connections)).

### Cluster and ClusterSet targets accept endpoint lists

`(Router) Host` and `(Router) Port` on both container types now accept comma-separated lists (user guide [4.1](targets-and-properties.md#target-properties)). No target metadata changed, so an agent-side deploy is sufficient and existing single-endpoint targets are unaffected. **No operator action.**

### ClusterSet health names an unreachable member: new `fallback_reason` value `MEMBER_UNREACHABLE`

A ClusterSet target whose agent host could reach one listed endpoint but not another member that Group Replication still
considered online used to fall back with `fallback_reason` `PARSE_FAILED` (or `TIMEOUT` once several members were
unreachable), which pointed at the wrong remedy. It now reports **`MEMBER_UNREACHABLE`**, with the remedy in user guide [2.2](prerequisites.md#mysql-shell-for-clusterset-targets):
open a path from the agent host to every member of every cluster on its MySQL port, not only to the members listed on the
target. Two related changes ship in the same fix: a listed endpoint that is not part of a ClusterSet no longer stops the
endpoint loop (the next endpoint is tried, and `NOT_A_CLUSTERSET` is reported only when every endpoint says so), and the
MySQL Shell process budget now reserves time for the AdminAPI's status fan-out to every member, so a single-endpoint health
check can take up to 60 seconds rather than 30 before it reports (user guide [4.1](targets-and-properties.md#target-properties)). No target metadata changed; an agent-side
deploy is sufficient. **Operator action only if you match on `fallback_reason`:** an incident rule, notification or script
that keyed on `PARSE_FAILED` or `TIMEOUT` to catch an unreachable member should add `MEMBER_UNREACHABLE`.

### Compliance results change: the privilege rules now see role-granted privileges

The `SecurityAccounts` configuration snapshot now reports **effective** privileges. Every `has_*` privilege flag counts the
account's own grants plus every role it can reach (roles granted to it, at any nesting depth, and the server's
`mandatory_roles`), and `has_mysql_schema_write` honours partial revokes on the `mysql` schema. The seven account-privilege
rules in the MySQL Security Standard (Over-Privileged Accounts, Accounts With Grant Option, Accounts With File Privilege,
Accounts With Process Privilege, Accounts With Shutdown Privilege, Accounts With Super Privilege, Accounts With MySQL Schema
Write Access) evaluate those flags, so after the first configuration snapshot on this drop (24-hour schedule, user guide [9.2](compliance-rules.md#associating-standards-and-reading-results))
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
its **License Key** property (guide [4.1](targets-and-properties.md#target-properties)). While the `License` metric's status
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
the agent side in the same maintenance window as the OMS side (guide [3.4](install-and-upgrade.md#upgrading)).

Verify afterwards, against the beta target type:

```
emcli get_threshold -target_name="<database target>" -target_type=ip_mysql_database_beta
```

The `License` conditions — `licensed` and `days_remaining` — must be listed. If
they are not, the metadata was stored but not activated: repeat the OMS deploy,
let the restart finish, and redeploy to the agents.

The MySQL Cluster and MySQL ClusterSet target types are unchanged in this drop.
Chapter [3.4](install-and-upgrade.md#upgrading) of the user guide remains the authoritative upgrade procedure.

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
