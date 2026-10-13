---
title: Troubleshooting
nav_order: 12
---

# Troubleshooting

The things people actually hit, what each one looks like, and what to change.

**In this page:** The licence gate · An empty metric group · Install and deploy · Connecting to Db2 · Jobs · Compliance shows nothing · Amazon RDS for Db2 · OMS licence-count connection · Support

Nearly everything that goes wrong in the first hour with this plug-in is one of a small number of things. This page is that list rather than a general guide to Enterprise Manager.

**If a target is Up but almost every page is empty, it is the licence key.** That single cause accounts for more first-hour reports than everything else here combined, so it is the first section.

## The licence gate {#licence-gate}

**Symptom.** The target shows **Up**. Its pages are empty, or nearly so. There is a Critical incident on the `License` metric, and every other metric group reports a collection error beginning:

```
Collection stopped by license status
```

**Cause.** Every `ip_db2_database` target needs a licence key for `ip.em.xdb2` in its **Plugin Licence Key** property. While the status is `License Required`, `Invalid Signature` or `Expired`, the plug-in stops ordinary collection on that target — with four deliberate exceptions, so you can always tell why: **License** itself (so you can see the status), **Response** (so availability keeps working), **Version**, and **CollectorStatus** (which reports each stopped group as `DISABLED`). Availability keeps reporting, which is why the target stays *Up* rather than going *Down* — the incident and the collection errors are the signal, not the target status.

**Fix.** Read the licence status on the `License` metric and act on it:

| Status | Meaning | What to do |
| :--- | :--- | :--- |
| `Active` | The key is genuine, issued for `ip.em.xdb2`, and in date. | Nothing. |
| `License Required` | No key has been entered. | Enter your key in the Plugin Licence Key property. |
| `Invalid Signature` | The key text was altered or truncated, or it was issued for a different plug-in identity — for example, an Open Beta key (`ip.em.xdbb`) on a GA target. | Paste the key exactly as issued, as one line, or request a key issued for `ip.em.xdb2`. |
| `Expired` | The key's expiry date has passed. | Request a new key. |
| `Exceeded Limit` | More `ip_db2_database` targets exist than the key's instance count. Only this plug-in's own targets count, never beta targets or targets under a different Db2 plug-in. Collection keeps running; the status alert stays open. | Request an increased instance count, or remove a target. |

The key is checked on the agent host every 15 minutes, and again as soon as the property changes. Collections resume at their next interval once the key is accepted — you do not need to restart anything. The `License` metric also warns 30 days, and goes critical 7 days, before a key expires.

**Related:** [Licensing](targets-and-properties.md#licensing) · [Getting started](getting-started.md#licence-key) · [Trial setup](trial.md#your-licence-key)

## An empty metric group {#empty-group}

**Symptom.** One metric group, or one region of a page, stays empty while the rest of the target collects.

**Fix.** Open the target's **CollectorStatus** metric under **All Metrics**. It has one row per metric group, with a `Status`, a plain-language `Reason`, when the agent last tried, and how many rows it returned:

| Status | What it means | What to do |
| :--- | :--- | :--- |
| `OK` | The group collected and returned rows. | Nothing; if the page is still empty, wait for the upload. |
| `NOT_CONFIGURED` | The feature is not set up on this database — HADR on a standalone database, for example. | Nothing; empty is the right answer. |
| `NOT_COLLECTED_YET` | The group has not completed its first collection, or the history it needs has not built up. | Wait. Groups collect on intervals from 5 minutes to 24 hours. |
| `NO_DATA` | The query ran and legitimately returned nothing this cycle — no lock waits right now, for example. | Nothing. |
| `COLLECTION_ERROR` | The collection failed. `Reason` carries the SQLSTATE and the message. | Act on the reason. A shipped Critical alert fires after two failures in a row. |
| `DISABLED` | The group is gated off for this target by design: no active licence, the agent is not local (diagnostic-log monitoring), an HADR standby that cannot serve it, or an unsupported Db2 version or topology. | Nothing about the database; the reason names the monitoring or licensing change. |

**All the performance numbers are zero.** If a `MON_*_METRICS` database configuration switch is `NONE`, Db2 returns zeros instead of failing, so pages look healthy while measuring nothing. The `Monitor_Metrics` group raises a warning, and its message gives the online fix — see [Alerts and thresholds](alerts-and-templates.md#default-thresholds). Databases created before Db2 9.7 and upgraded since are the ones most likely to be affected.

**After an in-place Db2 upgrade, groups read `DISABLED` or the version looks wrong.** The detected version refreshes on an agent restart or a plug-in redeploy; to refresh it at once, run `emctl reload agent dynamicproperties <target name>:ip_db2_database` on the agent host.

**Related:** [Monitoring pages](monitoring-pages.md) · [Supported versions and platforms](prerequisites.md#supported-versions)

## Install and deploy {#deploy}

**`Incompatible version` at import.** The plug-in ships one artifact per Enterprise Manager line, each built with that line's development kit, and Enterprise Manager refuses the other one. Use `24.1.1.0.0_ip.em.xdb2_2000_0.opar` on Enterprise Manager 24ai and `13.5.2.0.0_ip.em.xdb2_2000_0.opar` on Enterprise Manager 13.5, and check its SHA-256 checksum against [Download](install-and-upgrade.md#download).

**`deploy_plugin_on_server` rejects `-sys_password` on 24ai.** Enterprise Manager 24ai takes `-dbUser=SYS -dbPassword=<repository SYS password>` instead.

**The OMS restarted during deployment.** Expected. `emcli get_plugin_deployment_status -plugin=ip.em.xdb2` tells you when it is back.

**A redeploy or an update appears "already deployed" and did not actually change anything.** Confirm you pinned the `:version` on both the server and agent deploy commands; without it, an agent that already has the plug-in can be skipped. See [Deploy to agents](install-and-upgrade.md#deploy-agents).

**A metric added by an update shows no data.** Deploy the agent side in the same maintenance window as the OMS side. Until you do, metrics an update adds have nowhere to come from, and their pages stay empty while everything else keeps working.

**Moving from the Open Beta.** GA does not install over the beta, and beta targets do not become GA targets. Install GA side by side and re-create the targets — see [Moving from the beta to GA](beta-pre-release.md).

**Related:** [Install and upgrade](install-and-upgrade.md)

## Connecting to Db2 {#connecting}

**Target stays Down.** Down means the database or instance cannot be reached: the host is unreachable, the connection is refused, or the instance is stopped. Confirm the agent can open a TCP connection to the Db2 listener port (`50000` by default, or the `ssl_svcename` port for a TLS instance) — see [Network and ports](prerequisites.md#network). Then confirm the `oem_monitor` user can connect from a client on the agent host: `db2 connect to <DBNAME> user oem_monitor using <password>`.

**The target is Up, but shows a metric collection error.** The database answered, but the plug-in cannot monitor it. These are reported as a metric collection error rather than "target is down", and the error text says what to fix:

- authentication failed — a wrong or expired password, or no monitoring password set;
- the monitoring user lacks a privilege (`SQL0551N` / `SQLSTATE 42501`) — see below;
- the database is **quiesced** and the monitoring user has no `QUIESCE_CONNECT` authority (`SQL20157N`) — the usual case for the least-privilege user while a database is quiesced;
- a TLS problem (see below);
- the JDBC driver could not be loaded.

A quiesced, quiesce-pending or roll-forward-pending database still counts as Up; the `db_status` column shows which state it is in.

**Collections fail with `SQLCODE=-551 SQLSTATE=42501`.** The monitoring user is missing `SQLADM`. Re-run the grant in [The monitoring role](prerequisites.md#monitoring-role).

**A TLS error names the certificate.** Each TLS failure says which of three things went wrong:

- **The certificate does not name the host.** Connect by a host name the certificate holds, or set **TLS Hostname Validation** to `OFF`, which keeps the trust check and skips only the name check.
- **The certificate is not trusted.** If **Use SSL/TLS?** is `yes` and no **Client Truststore** is set, the driver validates against the agent JVM's default `cacerts`, which does not trust a private or self-signed certificate. Point **Client Truststore Location** (and type and password) at a store holding the Db2 server certificate.
- **No protocol or cipher in common** with the server.

See [Optional transport security](prerequisites.md#tls).

**An HADR standby target collects almost nothing.** Expected when reads on standby are off: the standby accepts no connections, so it reads Up and CollectorStatus reports the other groups as `DISABLED`. See [Monitoring a standby](hadr-monitoring.md#monitoring-a-standby).

**Related:** [Prerequisites](prerequisites.md#network) · [The monitoring role](prerequisites.md#monitoring-role)

## Jobs {#jobs}

**A job fails with `Unable to get credentials for defaultHostCred`.** The preferred credential set the job uses is not set for the target. The local jobs use **IBM DB2 Database Host Credentials**; Purge Stale Plugin Cache and Collect IBM DB2 Plug-in Diagnostics use **IBM DB2 Plug-in Agent Owner Credentials**. See [Credentials](jobs-and-metric-extensions.md#credentials).

**The Kill Blocking Application button reports *The kill job could not run. Check that preferred host credentials are set for this target.*** Set the target's **IBM DB2 Database Host Credentials** — the button submits the job without asking for any.

**A local job fails with `ERROR: refusing to run: this job acts on the Db2 instance on the agent's own host…`.** The agent monitoring this target is not on the Db2 host, so the job refuses rather than act on whatever Db2 instance the agent host has. Run it from an agent on the Db2 host, or, for a forced application, use the remote **Force Application** job. This is expected, not a bug, on Amazon RDS for Db2 — see below.

**A local job fails with `Can't open perl script ".../killagent.pl": Permission denied`.** On Linux or UNIX, the Db2 instance owner cannot read the agent's plug-in files. Add the instance owner to the agent install owner's group on the Db2 host, then submit the job again — see [The five local jobs](jobs-and-metric-extensions.md#local-jobs).

**A remote admin job fails at once with `Default preferred credentials are not set`.** A remote job needs **both** **IBM DB2 Database Admin Credentials** and **IBM DB2 Plug-in Agent Owner Credentials** set on the target. It never falls back to the monitoring user.

**The online backup job fails with `SQL2413N`.** The database uses circular logging, so an online backup is not allowed. Online backups need archive logging (`LOGARCHMETH1` not `OFF`); the Configuration Best Practices compliance standard flags circular logging too.

**`Purge Stale Plugin Cache` fails even though a credential is set.** Check *which* OS account the credential runs as. Purge Stale Plugin Cache needs the account that **owns the agent installation** (commonly `oracle`), not the Db2 instance owner the local jobs use. A credential for the wrong user authenticates successfully and then cannot read the job's script, or cannot delete the files (`Deleted 0 of N orphaned cache file(s)`). See [Jobs](jobs-and-metric-extensions.md#purge-stale-cache).

**Diagnostic-log monitoring reports nothing, or a local job type is refused, on a database you know is reachable.** Confirm the agent is actually co-located on the Db2 host, not just network-reachable — these need a local agent by design. CollectorStatus reports `Diag_Log_File_Monitoring` as `DISABLED` when it is not. See [Network and ports](prerequisites.md#network).

**Related:** [Jobs](jobs-and-metric-extensions.md) · [Preferred Credentials](prerequisites.md#preferred-credentials)

## Compliance shows nothing {#compliance}

**A standard is installed but the compliance dashboard shows no Db2 bar, or Association Count reads 0.** Nothing evaluates until you associate the standard with your targets — this is the most common cause of an "installed but silent" compliance standard. See [Associate a standard with targets](compliance-standards.md#associate).

**Association Count is non-zero, but a standard still shows no results.** Its rules read a daily configuration snapshot; a newly associated target legitimately shows nothing until that snapshot has run once. See [Let a configuration collection run](compliance-standards.md#let-a-configuration-collection-run).

**The audit-posture collection reports an authorization error.** `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE` are readable by `PUBLIC` on a default installation; a hardened site may have revoked that. Grant explicit `SELECT` on both views — see [The monitoring role](prerequisites.md#monitoring-role). Every other collection is unaffected; only the audit-posture rules have no data to evaluate until the grant is in place.

**Related:** [Compliance standards](compliance-standards.md)

## Amazon RDS for Db2 {#rds-for-db2}

**Amazon RDS for Db2 is not certified in this release.** Monitoring may work against an RDS endpoint, since all metric collection runs over JDBC, but it has not been certified.

**The five local administrative jobs and diagnostic-log monitoring are unavailable on RDS.** This is expected, not a defect: RDS gives you no host shell, no local `db2` CLI, and no filesystem access to `db2diag.log`, and those capabilities depend on exactly that. The agent cannot be co-located with the instance.

If you are evaluating against RDS, tell us what you find — see [Support](#support).

**Related:** [Network and ports](prerequisites.md#network) · [Jobs](jobs-and-metric-extensions.md)

## OMS licence-count connection {#oms-licence-count}

**A limited-instance licence key's License group shows a metric collection error about the OMS.** For a key limited to fewer than 100 instances, the plug-in counts the `ip_db2_database` targets through the OMS. The error names the cause:

- **A missing setting.** A missing **OMS Host**, **OMS Port** or OMS credential is named as such. Set them on the target — see [The OMS settings](targets-and-properties.md#oms-settings).
- **Credentials rejected.** The **IBM DB2 OMS Monitoring Credentials** user must be able to view the `ip_db2_database` targets.
- **The certificate is not trusted.** The connection validates the OMS certificate and hostname by default, so an OMS presenting its default self-signed certificate fails.

The other metric groups keep collecting in every case, because the collection gate never depends on the count. An `Unlimited` key, or one for 100 instances or more, never contacts the OMS at all.

**Fix for the certificate, best first:**

1. **Import the OMS certificate into the agent's Java truststore.** The correct fix — validation stays on and credentials stay protected. The collector runs on the JVM that `JAVA_HOME` names in the agent's `emd.properties`, which for the central agent on the OMS host is the OMS home's JDK. As the agent owner:

   ```
   J=<the JAVA_HOME from emd.properties>
   $J/bin/keytool -printcert -sslserver <oms host>:<oms console port> -rfc > oms_chain.pem
   csplit -s -z -f oms_cert- oms_chain.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
   for f in oms_cert-*; do
     $J/bin/keytool -importcert -noprompt -trustcacerts -alias "em-oms-$f" -file "$f" \
       -keystore $J/jre/lib/security/cacerts -storepass <truststore password, default changeit>
   done
   ```

   On a JDK 9 or later the file is `$J/lib/security/cacerts`. Import into every agent that monitors a target with a limited key, and re-check after an agent patch that replaces the JDK. The next License collection should read `Active`.
2. **Set the target's `OMS: skip certificate validation (insecure, lab only)` property to `true`.** Stops validating the OMS certificate for this one connection. A warning is logged on every collection while it is set. Lab use only.
3. **Set the target's `OMS: allow cleartext HTTP fallback (insecure, lab only)` property to `true`.** Permits retrying the count over plain HTTP when HTTPS fails, sending the OMS password unencrypted. The weakest of the three options — lab use only, and also logs a warning on every collection.

**Related:** [Licensing](targets-and-properties.md#licensing) · [Install and upgrade](install-and-upgrade.md#after-upgrade)

## Support {#support}

If you need assistance with the IBM Db2 Plugin for Oracle Enterprise Manager:

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)

Include the following in your ticket, so we can reproduce what you are seeing:

- The plug-in version. Run `emcli list_plugins_on_server` and find `ip.em.xdb2` in the output.
- Your Enterprise Manager line, 13.5 or 24ai.
- Your Db2 version, 11.5 or 12.1.
- The page or metric involved, and the target's **CollectorStatus** row for it.
- A screenshot of what you are seeing.

If support asks for diagnostics, run the **Collect IBM DB2 Plug-in Diagnostics** job and attach the archive it writes — see [Collect diagnostics for support](jobs-and-metric-extensions.md#collect-diagnostics).

## Related

- [Getting started](getting-started.md) — the install path this page's symptoms usually trace back to
- [What's new](whats-new.md#known-issue) — the known issue in this release
- [Trial setup](trial.md#send-us-your-findings) — where to send a finding that is not on this page
