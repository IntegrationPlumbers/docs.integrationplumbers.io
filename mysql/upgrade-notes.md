---
title: Upgrade notes
nav_order: 4.5
---

# Upgrade Notes

Release notes for changes that need operator action beyond a routine deploy —
security remediation, target metadata that has to be activated, breaking column
changes. One section per drop, **newest first**.

Internal builds that were never shipped to a customer are not listed here.

## Open Beta — `24.1.9.N.0` / `13.5.9.N.0` (2026-09-01)

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
