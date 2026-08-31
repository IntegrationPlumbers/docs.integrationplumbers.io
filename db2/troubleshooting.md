---
title: Troubleshooting
nav_order: 12
---

# Troubleshooting

The things beta users actually hit, what each one looks like, and what to change.

**In this page:** The licence gate · Known issue: DB Status threshold · Install and deploy · Connecting to Db2 · Jobs · Compliance shows nothing · Amazon RDS for Db2 · OMS licence-count connection

Nearly everything that goes wrong in the first hour with this plug-in is one of a small number of things. This page is that list rather than a general guide to Enterprise Manager.

**If a beta target is Up but almost every page is empty, it is the licence key.** That single cause accounts for more first-hour reports than everything else here combined, so it is the first section.

## The licence gate {#licence-gate}

**Symptom.** The target shows **Up**. Its Home, Analysis, and Performance pages are empty, or nearly so. There is a Critical incident on the `License` metric, and every other metric group reports a collection error reading:

```
Collection stopped by license status: <status>
```

**Cause.** Every `ip_db2_database_beta` target needs a beta licence key in its **Plugin Licence Key** property. While the status is anything but `Active`, the plug-in stops ordinary collection on that target — with three deliberate exceptions, so you can always tell why: the **License** metric itself (so you can see the status), **Response** (so the target reads unlicensed rather than simply Down), and **Version** (collected at target-add time, before a licence property even exists to check). Availability keeps reporting, which is why the target stays *Up* rather than going *Down* — the incident and the collection errors are the signal, not the target status.

**Fix.** Read the `Status` column of the `License` metric and act on it:

| Status | Meaning | What to do |
| :--- | :--- | :--- |
| `Active` | The key is genuine, issued for `ip.em.xdbb`, and in date. | Nothing. |
| `License Required` | No key has been entered. | Enter your beta key in the Plugin Licence Key property. |
| `Invalid Signature` | The key text was altered, or it was issued for a different plug-in identity — for example, a future GA key on this beta build. | Paste the key exactly as issued, as one line, or request a key issued for `ip.em.xdbb`. |
| `Expired` | The key's expiry date has passed. | Request a new key. |
| `Exceeded Limit` | More `ip_db2_database_beta` targets exist than the key's instance count. Only this plug-in's own targets count, never targets under a different Db2 plug-in. | Request an increased instance count, or remove a target. |

The key is checked on the agent host every 15 minutes, and again as soon as the property changes. Collections resume at their next interval once the key is accepted — you do not need to restart anything.

**Related:** [Getting started](getting-started.md#licence-key) · [Trial setup](trial.md#your-beta-key)

## Known issue: the "DB Status" detailed-response threshold {#db-status-threshold}

**Symptom.** You set a Warning or Critical threshold on the **DB Status** column of the detailed response metric — typically to the healthy value, `ACTIVE` — and a CRITICAL incident fires immediately on every healthy database, and never clears.

**Cause.** In `24.1.9.7.0` / `13.5.9.2.0` that condition ships with an inverted comparison operator: it alerts when the status *equals* your threshold instead of when it *deviates* from it.

**Fix.** Leave that one threshold **Not Defined** in this drop — it ships that way and is harmless untouched. The equivalent db_status condition under DB Monitoring uses the correct deviation semantics and can be used instead. The operator is corrected in the next drop.

## Install and deploy {#deploy}

**`Incompatible version` at import.** The beta ships one artifact per Enterprise Manager line, each built with that line's development kit, and EM refuses the other one. Use `24.1.9.7.0` on EM 24ai and `13.5.9.2.0` on EM 13.5.

**A new drop's metrics show no data.** Some drops move target metadata. When they do, the OMS side and the agent side must both be deployed — deploy the agent side in the same maintenance window as the OMS side. Until you do, metrics added by that drop have nowhere to come from and their pages stay empty while everything else keeps working.

**The OMS restarted during deployment.** Expected on drops that move target metadata. `emcli get_plugin_deployment_status -plugin=ip.em.xdbb` tells you when it is back.

**Replacing a beta drop does not behave like an in-place upgrade.** Beta-to-beta moves are undeploy-then-redeploy, not a silent in-place update — see [Upgrade from an earlier drop](install-and-upgrade.md#upgrade). If a drop appears "already deployed" and did not actually update, confirm you pinned the `:version` on both the server and agent deploy commands.

**Related:** [Install and upgrade](install-and-upgrade.md)

## Connecting to Db2 {#connecting}

**Target stays Down.** Confirm the agent can open a TCP connection to the Db2 listener port (`50000` by default, or the `ssl_svcename` port for a TLS instance) — see [Network and ports](prerequisites.md#network). Then confirm the `oem_monitor` user can connect from a client on the agent host: `db2 connect to <DBNAME> user oem_monitor using <password>`.

**Collections fail with `SQLCODE=-551 SQLSTATE=42501`.** The monitoring user is missing `SQLADM`. This authorization error is the expected, measured result of removing it — 21 of 24 collection categories depend on it. Re-run the grant in [The monitoring role](prerequisites.md#monitoring-role).

**TLS connection fails against a private or self-signed Db2 certificate.** If **Use SSL/TLS?** is `yes` and no **Client Truststore** is set, the driver validates against the agent JVM's default `cacerts`, which does not trust a private certificate. Point **Client Truststore Location** (and type and password) at a store holding the Db2 server certificate. See [Optional transport security](prerequisites.md#tls).

**Related:** [Prerequisites](prerequisites.md#network) · [The monitoring role](prerequisites.md#monitoring-role)

## Jobs {#jobs}

**A job fails with `Unable to get credentials for defaultHostCred`.** No Agent Host Credential is set for the target under Preferred Credentials. Set one — see [Preferred Credentials](prerequisites.md#preferred-credentials).

**`Purge Stale Plugin Cache` fails even though a host credential is set.** Check *which* OS account the credential runs as. The five administrative jobs need the **Db2 instance owner**; Purge Stale Plugin Cache needs the account that **owns the agent installation** (commonly `oracle`) — a different account. A credential for the wrong user authenticates successfully and then cannot read the job's script, so the symptom looks identical to a missing credential. See [Jobs](jobs-and-metric-extensions.md#purge-stale-cache).

**A local-only job or `Diag_Log_File_Monitoring` fails, or the job type is not even offered, on a database you know is reachable.** Confirm the agent is actually co-located on the Db2 host, not just network-reachable — these jobs and diagnostic-log monitoring need a local agent by design. See [Network and ports](prerequisites.md#network). This is expected, not a bug, on Amazon RDS for Db2 — see below.

**Related:** [Jobs](jobs-and-metric-extensions.md) · [Preferred Credentials](prerequisites.md#preferred-credentials)

## Compliance shows nothing {#compliance}

**A standard is installed but the compliance dashboard shows no Db2 bar, or Association Count reads 0.** Nothing evaluates until you associate the standard with your targets — this is the most common cause of an "installed but silent" compliance standard. See [Associate a standard with targets](compliance-standards.md#associate).

**Association Count is non-zero, but Configuration Best Practices still shows no results.** Its rules read a daily configuration snapshot; a newly associated target legitimately shows nothing until that snapshot has run once. See [Let a configuration collection run](compliance-standards.md#let-a-configuration-collection-run).

**The audit-posture collection reports an authorization error.** `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE` are readable by `PUBLIC` on a default installation; a hardened site may have revoked that. Grant explicit `SELECT` on both views — see [The monitoring role](prerequisites.md#monitoring-role). Every other collection is unaffected; only the audit-posture rules have no data to evaluate until the grant is in place.

**Related:** [Compliance standards](compliance-standards.md)

## Amazon RDS for Db2 {#rds-for-db2}

**The five administrative jobs, the Kill Application action, and diagnostic-log monitoring are unavailable on RDS.** This is expected, not a defect: RDS gives you no host shell, no local `db2` CLI, and no filesystem access to `db2diag.log`, and all six capabilities depend on exactly that. All JDBC-based metric collection — performance, availability, storage, locks, HADR, backup, top-SQL, and configuration — continues to work against an RDS endpoint over the network.

**Compatibility with RDS is documentation-verified only in this release**, not lab-certified. The `CONNECT` + `SQLADM` grant path is expected to work unchanged, since the master user's database-scoped authority can issue both grants without `SYSADM`, but this has not been confirmed against a live RDS instance. If you are evaluating against RDS, findings here are especially valuable — see [What's new](whats-new.md#beta-status) and [Trial setup](trial.md#send-us-your-findings).

**Related:** [Network and ports](prerequisites.md#network) · [Jobs](jobs-and-metric-extensions.md)

## OMS licence-count connection {#oms-licence-count}

**A limited-instance licence key's instance count fails to validate, most often right after an upgrade.** The plug-in's licence-count call to the OMS validates the OMS certificate by default. If your OMS presents a self-signed certificate, that connection now fails where an older build's connection — which did not validate the certificate at all — previously "succeeded." That is the fix working, not a regression: the earlier behavior exposed OMS credentials to anyone able to present a certificate on the management segment.

**Fix, best first:**

1. **Import the OMS certificate into the agent's JVM truststore.** The correct fix — validation stays on and credentials stay protected.
2. **Set the target's `OMS: skip certificate validation (insecure, lab only)` property to `true`.** Stops validating the OMS certificate for this one connection. A warning is logged on every collection while it is set. Lab use only.
3. **Set the target's `OMS: allow cleartext HTTP fallback (insecure, lab only)` property to `true`.** Permits retrying the count over plain HTTP when HTTPS fails, sending the OMS password Base64-encoded and unencrypted. The weakest of the three options — lab use only, and also logs a warning on every collection.

An `Unlimited` licence key never contacts the OMS at all, so this only affects targets on a limited-instance key.

**Related:** [Targets and properties](targets-and-properties.md#target-properties) · [Install and upgrade](install-and-upgrade.md#after-upgrade)

## Support

If you need assistance with the IBM DB2 Plugin for Oracle Enterprise Manager:

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)

Include the following in your ticket, so we can reproduce what you are seeing:

- The plug-in version. Run `emcli list_plugins_on_server` and find `ip.em.xdbb` in the output.
- Your Enterprise Manager line, 13.5 or 24ai.
- Your Db2 version, 11.5 or 12.1.
- The page or metric involved.
- A screenshot of what you are seeing.

## Related

- [Getting started](getting-started.md) — the install path this page's symptoms usually trace back to
- [What's new](whats-new.md#beta-status) — what is and is not verified yet in this release
- [Trial setup](trial.md#send-us-your-findings) — where to send a finding that is not on this page
