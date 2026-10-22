---
title: Troubleshooting
nav_order: 12
---

# Troubleshooting

The things people actually hit, what each one looks like, and what to change. This page is for the DBA or Enterprise Manager administrator looking at a target that is empty, wrong or failing a job. Nearly everything that goes wrong in the first hour with this plug-in is one of a small number of things, so this page is that list rather than a general guide to Enterprise Manager.

**In this page:** The licence gate · An empty metric group · Install and deploy · After the upgrade from GA · Connecting to Db2 · Jobs · Compliance shows nothing · Amazon RDS for Db2 · OMS licence-count connection · Logs · Known issues in this release · Getting support

**If a target is Up but almost every page is empty, it is the licence key.** That single cause accounts for more first-hour reports than everything else here combined, so it is the first section.

For a target whose pages are empty or partly filled, open its **Monitoring Readiness** page first: it checks the monitoring connection, the licence, the supported version, the monitor authority, every metric group's collection, the monitor switches, deadlock capture, HADR and the diagnostic log, and shows the statement to run for each fix (see [Monitoring Readiness](monitoring-pages.md#monitoring-readiness)). A [troubleshooting guide for AI assistants](https://docs.integrationplumbers.io/db2/ai/troubleshooting.md) covers the same checks, and the Enterprise Manager set-up behind the jobs and the licence count, in a form you can load into your own assistant together with the page's results, before you raise a service request.

## The licence gate {#licence-gate}

**Symptom.** The target shows **Up**. Its pages are empty, or nearly so. There is a Critical incident on the `License` metric, and every other metric group reports a collection error beginning:

```
Collection stopped by license status
```

**Cause.** Every `ip_db2_database` target needs a licence key for `ip.em.xdb2` in its **Plug-in Licence Key** credential (the *IBM DB2 Plug-in Licence Monitoring Credentials* set; a target upgraded from GA may still carry it in the older **Plugin Licence Key** property, which is read while the credential is empty). While the status is `License Required`, `Invalid Signature` or `Expired`, the plug-in stops ordinary collection on that target, with five deliberate exceptions so you can always tell why: **License** itself (so you can see the status), **Response** (so availability keeps working), **Version**, **CollectorStatus** (which reports each stopped group as `DISABLED`), and **readiness_summary** (so the Overview still counts the licence check). Availability keeps reporting, which is why the target stays *Up* rather than going *Down*: the incident and the collection errors are the signal, not the target status.

**Fix.** Read the licence status on the `License` metric and act on it:

| Status | Meaning | What to do |
| :--- | :--- | :--- |
| `Active` | The key is genuine, issued for `ip.em.xdb2`, and in date. | Nothing. |
| `License Required` | No key has been entered. | Enter your key in the Plug-in Licence Key credential: see [Licensing](targets-and-properties.md#licensing). |
| `Invalid Signature` | The key text was altered or truncated, or it was issued for a different plug-in identity, for example an Open Beta key (`ip.em.xdbb`) on a GA target. | Paste the key exactly as issued, as one line, or request a key issued for `ip.em.xdb2`. |
| `Grace Period` | The key expired less than 14 days ago. Collection continues, and the status alert is a Warning. | Request a renewed key and set it before the 14 days end. |
| `Expired` | The key expired more than 14 days ago. | Request a new key. |
| `Exceeded Limit` | More `ip_db2_database` targets exist than the key's instance count. Only this plug-in's own targets count, never beta targets or targets under a different Db2 plug-in. Collection keeps running; the status alert stays open. | Request an increased instance count, or remove a target. |

The key is checked on the agent host every 15 minutes, and at every collection. Collections resume at their next interval once the key is accepted; you do not need to restart anything. The `License` metric also warns 30 days, and goes critical 7 days, before a key expires.

**Related:** [Licensing](targets-and-properties.md#licensing) · [Getting started](getting-started.md#licence-key) · [Trial setup](trial.md#your-licence-key)

## An empty metric group {#empty-group}

**Symptom.** One metric group, or one region of a page, stays empty while the rest of the target collects.

**Fix.** Open the target's **CollectorStatus** metric under **All Metrics**. It has one row per metric group, with a `Status`, a plain-language `Reason`, when the agent last tried, and how many rows it returned:

| Status | What it means | What to do |
| :--- | :--- | :--- |
| `OK` | The group collected and returned rows. | Nothing; if the page is still empty, wait for the upload. |
| `NOT_CONFIGURED` | The feature is not set up on this database: HADR on a standalone database, for example. | Nothing; empty is the right answer. |
| `NOT_COLLECTED_YET` | The group has not completed its first collection, or the history it needs has not built up. | Wait. Groups collect on intervals from 5 minutes to 24 hours. |
| `NO_DATA` | The query ran and legitimately returned nothing this cycle: no lock waits right now, for example. | Nothing. |
| `COLLECTION_ERROR` | The collection failed. `Reason` carries the SQLSTATE and the message. | Act on the reason. A shipped Critical alert fires after two failures in a row. |
| `DISABLED` | The group is gated off for this target by design: no active licence, the agent is not local (diagnostic-log monitoring), an HADR standby that cannot serve it, or an unsupported Db2 version or topology. | Nothing about the database; the reason names the monitoring or licensing change. |

**All the performance numbers are zero.** If a `MON_*_METRICS` database configuration switch is `NONE`, Db2 returns zeros instead of failing, so pages look healthy while measuring nothing. The `Monitor_Metrics` group raises a warning, and its message gives the online fix: see [Monitor_Metrics](metrics-reference.md#monitor-metrics). Monitoring Readiness shows the same switches with the statement to run. Databases created before Db2 9.7 and upgraded since are the ones most likely to be affected.

**After an in-place Db2 upgrade, groups read `DISABLED` or the version looks wrong.** The detected version refreshes on an agent restart or a plug-in redeploy; to refresh it at once, run `emctl reload agent dynamicproperties <target name>:ip_db2_database` on the agent host.

**Related:** [Monitoring pages](monitoring-pages.md) · [Supported versions and platforms](prerequisites.md#supported-versions)

## Install and deploy {#deploy}

**`Incompatible version` at import.** The plug-in ships one artifact per Enterprise Manager line, each built with that line's development kit, and Enterprise Manager refuses the other one. Use `24.1.2.0.0_ip.em.xdb2_2000_0.opar` on Enterprise Manager 24ai and `13.5.3.0.0_ip.em.xdb2_2000_0.opar` on Enterprise Manager 13.5, and verify it first: see [Verify the download](install-and-upgrade.md#verify).

**`deploy_plugin_on_server` rejects `-sys_password` on 24ai.** Enterprise Manager 24ai takes `-dbUser=SYS -dbPassword=<repository SYS password>` instead.

**The OMS restarted during deployment.** Expected. `emcli get_plugin_deployment_status -plugin=ip.em.xdb2` tells you when it is back.

**A redeploy or an update appears "already deployed" and did not actually change anything.** Confirm you pinned the `:version` on both the server and agent deploy commands; without it, an agent that already has the plug-in can be skipped. See [Deploy to agents](install-and-upgrade.md#deploy-agents).

**A metric added by an update shows no data.** Deploy the agent side in the same maintenance window as the OMS side. Until you do, metrics an update adds have nowhere to come from, and their pages stay empty while everything else keeps working.

**Moving from the Open Beta.** GA does not install over the beta, and beta targets do not become GA targets. Install GA side by side and re-create the targets: see [Moving from the beta to GA](beta-pre-release.md).

**Related:** [Install and upgrade](install-and-upgrade.md)

## After the upgrade from GA {#upgrade}

**New charts or columns stay empty after the upgrade, and the licence-status alert does not fire.** The OMS has not been restarted since the deploy. It keeps each target type's column list in memory, so columns this release adds (the Transaction Log I/O chart on Performance, the cache rate chart on Memory & Sorts, `license_severity`) stay empty until `emctl stop oms; emctl start oms`. See [Upgrade notes](upgrade-notes.md#restart-oms).

**A threshold or template you set on a lock or session group is gone.** Seven groups are renamed in this release, and thresholds, templates and incident rules set on the old names do not move. Set them again on the new names. See [Upgrade notes](upgrade-notes.md#renamed-groups).

**The SQL page shows a statement twice.** A window that reaches back before the upgrade shows the old literal-text rows and the new digest row. See [Upgrade notes](upgrade-notes.md#statement-keys).

**Compliance scores dropped, and incidents opened, after the upgrade.** New rules check settings that are Db2's own defaults. Decide per rule what to do: see [Upgrade notes](upgrade-notes.md#compliance-scores).

**The License group shows a collection error about a missing OMS setting, on a key for 100 or more instances.** Those keys are counted now, so they need the OMS settings smaller keys already needed. See [The OMS settings](targets-and-properties.md#oms-settings).

**One instance-level breach opened several incidents.** After you add an IBM Db2 Instance target, the instance-scope groups alert on the instance and on each of its databases until you clear those thresholds on the database targets. See [Duplicate alerts](targets-and-properties.md#duplicate-alerts).

**The page names changed.** Home is Overview, Analysis is Locks, SQL Analytics is SQL, Backup History is Backup, and HADR is High Availability. See [Upgrade notes](upgrade-notes.md#page-names).

**Related:** [Upgrade notes](upgrade-notes.md) · [Install and upgrade](install-and-upgrade.md#upgrade)

## Connecting to Db2 {#connecting}

**Target stays Down.** Down means the database or instance cannot be reached: the host is unreachable, the connection is refused, or the instance is stopped. Confirm the agent can open a TCP connection to the Db2 listener port (`50000` by default, or the `ssl_svcename` port for a TLS instance): see [Network and ports](prerequisites.md#network). Then confirm the `oem_monitor` user can connect from a client on the agent host: `db2 connect to <DBNAME> user oem_monitor using <password>`.

**The target is Up, but shows a metric collection error.** The database answered, but the plug-in cannot monitor it. These are reported as a metric collection error rather than "target is down", and the error text says what to fix:

- authentication failed: a wrong or expired password, or no monitoring password set;
- the monitoring user lacks a privilege (`SQL0551N` / `SQLSTATE 42501`): see below;
- the database is **quiesced** and the monitoring user has no `QUIESCE_CONNECT` authority (`SQL20157N`): the usual case for the least-privilege user while a database is quiesced;
- a TLS problem (see below);
- the JDBC driver could not be loaded.

A quiesced, quiesce-pending or roll-forward-pending database still counts as Up; the `db_status` column shows which state it is in.

**Collections fail with `SQLCODE=-551 SQLSTATE=42501`.** The monitoring user is missing `SQLADM`: re-run the grant in [The monitoring role](prerequisites.md#monitoring-role). If the message names a `NULLID` package (for example `NULLID.SYSSH100`), the database was created `RESTRICTIVE`, as every Amazon RDS for Db2 database is, and the user needs EXECUTE on the `NULLID` packages: see [RESTRICTIVE databases](prerequisites.md#restrictive).

**A Kerberos target reports *Kerberos authentication failed*.** It is a metric collection error, not a Down target, and an unreachable KDC is reported the same way. The message says what to check and gives the driver's reason. Common causes: a wrong password or an expired keytab key; a `krb5.conf` that does not name the realm or the KDC; clock skew over 5 minutes; the Db2 service principal missing from the instance's keytab, or the keytab not reaching the engine (`DB2ENVLIST`); `empty realm part not allowed`, which means the instance advertises its principal without a realm (set `DB2_KRB5_PRINCIPAL`); or an encryption type the agent's Java does not support. See [Kerberos authentication](prerequisites.md#kerberos).

**A TLS error names the certificate.** Each TLS failure says which of three things went wrong:

- **The certificate does not name the host.** Connect by a host name the certificate holds, or set **TLS Hostname Validation** to `OFF`, which keeps the trust check and skips only the name check.
- **The certificate is not trusted.** If **Use SSL/TLS?** is `yes` and no **Client Truststore** is set, the driver validates against the agent JVM's default `cacerts`, which does not trust a private or self-signed certificate. Point **Client Truststore Location** (and type and password) at a store holding the Db2 server certificate.
- **No protocol or cipher in common** with the server.

See [Optional transport security](prerequisites.md#tls).

**An HADR standby target collects almost nothing.** Expected when reads on standby are off: the standby accepts no connections, so it reads Up and CollectorStatus reports the other groups as `DISABLED`. See [Monitoring a standby](hadr-monitoring.md#monitoring-a-standby).

**Related:** [Prerequisites](prerequisites.md#network) · [The monitoring role](prerequisites.md#monitoring-role)

## Jobs {#jobs}

**A job fails with `Unable to get credentials for defaultHostCred`.** The preferred credential set the job uses is not set for the target. The local jobs use **IBM DB2 Database Host Credentials**; Purge Stale Plugin Cache and Collect IBM DB2 Plug-in Diagnostics use **IBM DB2 Plug-in Agent Owner Credentials**. See [Credentials](jobs-and-metric-extensions.md#credentials).

**Kill on the Locks or Sessions page reports *The kill job could not run. Check that preferred host credentials are set for this target.*** Set the target's **IBM DB2 Database Host Credentials**: the button submits the job without asking for any.

**Back Up Database reports that the backup did not run because a preferred credential is not set.** The dialog submits the remote **Online Backup** job, which needs the target's **IBM DB2 Database Admin Credentials** and **IBM DB2 Plug-in Agent Owner Credentials**, and Full privilege on the target for you. Deploy the plug-in to the agent as well as the OMS: an agent on an earlier version refuses the backup job and runs nothing.

**Back Up Database, or the Online Backup job, refuses a partitioned (DPF) database.** Expected: without `ON ALL DBPARTITIONNUMS` the job would back up only the partition its connection runs on, and that image cannot restore the database. The dialog shows a red note, and the job itself refuses a DPF database however it was submitted (Job Library, `emcli`, a saved or scheduled job), running nothing. Back up every partition on the server with `db2 backup database <db> on all dbpartitionnums ...`. If the refusal says the partition count could not be read, the admin user needs EXECUTE on `SYSPROC.DB_MEMBERS`, which PUBLIC holds only on a database not created `RESTRICTIVE`: run `GRANT EXECUTE ON FUNCTION SYSPROC.DB_MEMBERS TO USER <admin user>`, or give it SQLADM. See [Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs).

**A local job fails with `ERROR: refusing to run: this job acts on the Db2 instance on the agent's own host…`.** The agent monitoring this target is not on the Db2 host, so the job refuses rather than act on whatever Db2 instance the agent host has. Run it from an agent on the Db2 host, or, for a forced application, use the remote **Force Application** job. This is expected, not a bug, on Amazon RDS for Db2: see below.

**A local job fails with `Can't open perl script ".../killagent.pl": Permission denied`.** On Linux, the Db2 instance owner cannot read the agent's plug-in files. Add the instance owner to the agent install owner's group on the Db2 host, then submit the job again: see [The six local jobs](jobs-and-metric-extensions.md#local-jobs).

**A remote admin job fails at once with `Default preferred credentials are not set`.** A remote job needs **both** **IBM DB2 Database Admin Credentials** and **IBM DB2 Plug-in Agent Owner Credentials** set on the target. It never falls back to the monitoring user.

**A remote admin job or Explain on a TLS target fails at once with "Unable to resolve credential reference".** A target with **Use SSL/TLS?** = `yes` needs its client truststore credential set for jobs, even when the agent JVM's default `cacerts` trusts the server. Point the set at that `cacerts`: see [TLS targets](jobs-and-metric-extensions.md#tls-targets).

**Explain Plan says the explain tables are not set up, or a privilege is missing.** A DBA creates the Db2 explain tables once per database and grants the monitoring user `INSERT` and `SELECT` on them. The dialog names the cause: see [Explain SQL Statement](jobs-and-metric-extensions.md#explain).

**The online backup job fails with `SQL2413N`.** The database uses circular logging, so an online backup is not allowed. Online backups need archive logging (`LOGARCHMETH1` not `OFF`); the Configuration Best Practices compliance standard flags circular logging too.

**`Purge Stale Plugin Cache` fails even though a credential is set.** Check *which* OS account the credential runs as. Purge Stale Plugin Cache needs the account that **owns the agent installation** (commonly `oracle`), not the Db2 instance owner the local jobs use. A credential for the wrong user authenticates successfully and then cannot read the job's script, or cannot delete the files (`Deleted 0 of N orphaned cache file(s)`). On Windows the same message can mean a file is in use: run the job again later. See [Jobs](jobs-and-metric-extensions.md#purge-stale-cache).

**Diagnostic-log monitoring reports nothing, or a local job type is refused, on a database you know is reachable.** Confirm the agent is actually on the Db2 host, not just network-reachable: these need a local agent by design. CollectorStatus reports `Diag_Log_File_Monitoring` as `DISABLED` when it is not. See [Network and ports](prerequisites.md#network).

**Related:** [Jobs](jobs-and-metric-extensions.md) · [Preferred Credentials](prerequisites.md#preferred-credentials)

## Compliance shows nothing {#compliance}

**A standard is installed but the compliance dashboard shows no Db2 bar, or Association Count reads 0.** Nothing evaluates until you associate the standard with your targets. This is the most common cause of an "installed but silent" compliance standard. See [Associate a standard with targets](compliance-standards.md#associate).

**Association Count is non-zero, but a standard still shows no results.** Its rules read a daily configuration snapshot; a newly associated target legitimately shows nothing until that snapshot has run once. See [Let a configuration collection run](compliance-standards.md#let-a-configuration-collection-run).

**The audit-posture collection reports an authorization error.** `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE` are readable by `PUBLIC` on a default installation; a hardened site may have revoked that. Grant explicit `SELECT` on both views: see [The monitoring role](prerequisites.md#monitoring-role). Every other collection is unaffected; only the audit-posture rules have no data to evaluate until the grant is in place.

**Related:** [Compliance standards](compliance-standards.md)

## Amazon RDS for Db2 {#rds-for-db2}

**Amazon RDS for Db2 is not certified.** All metric collection runs over JDBC, and a lab run on Db2 12.1.5 on RDS verified it; the formal certified status still waits for sign-off. The monitoring user needs `ROLE_NULLID_PACKAGES` and `EXECUTE` on `NULLID.ATSQ0A`, because RDS databases are RESTRICTIVE.

**The six local administrative jobs, Kill and diagnostic-log monitoring are unavailable on RDS.** This is expected, not a defect: RDS gives you no host shell, no local `db2` CLI, and no file-system access to `db2diag.log`, and those capabilities depend on exactly that.

**Force Application and Online Backup fail with `SQL1092N` on RDS; RUNSTATS works.** The RDS master user holds SYSMON, SQLADM, DBADM, ACCESSCTRL and DATAACCESS, but not SYSADM, SYSCTRL, SYSMAINT or SECADM, which those two jobs need. Use RDS's own backups, or `rdsadmin.backup_database`. RUNSTATS works over the plain port, and over TLS with the RDS CA in the target's client truststore. TLS is opt-in on RDS. See [Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs).

If you are evaluating against RDS, tell us what you find: see [Getting support](#support).

**Related:** [Network and ports](prerequisites.md#network) · [Jobs](jobs-and-metric-extensions.md)

## OMS licence-count connection {#oms-licence-count}

**A limited-instance licence key's License group shows a metric collection error about the OMS.** For a key limited to a number of instances, the plug-in counts the `ip_db2_database` targets through the OMS. On Monitoring Readiness this shows as **License collection** reading Not functional. The error names the cause:

- **A missing setting.** A missing **OMS Host**, **OMS Port** or OMS credential is named as such. Set them on the target: see [The OMS settings](targets-and-properties.md#oms-settings).
- **Credentials rejected.** The **IBM DB2 OMS Monitoring Credentials** user must be able to view the `ip_db2_database` targets.
- **The certificate is not trusted.** The connection validates the OMS certificate and hostname by default, so an OMS presenting its default self-signed certificate fails.

The other metric groups keep collecting in every case, because the collection gate never depends on the count. An `Unlimited` key never contacts the OMS. IBM Db2 Instance targets never count and never contact it.

**Fix for the certificate, best first:**

1. **Import the OMS certificate into the agent's Java truststore.** The correct fix: validation stays on and credentials stay protected. The collector runs on the JVM that `JAVA_HOME` names in the agent's `emd.properties`, which for the central agent on the OMS host is the OMS home's JDK. As the agent owner:

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
2. **Set the target's OMS API Communication property** (`ip_db2_database_license_verification_mode`) **to `SECURE`.** HTTPS without a certificate check, for this one connection. Use it only where the OMS certificate cannot be imported.
3. **`INSECURE`** also allows a cleartext HTTP fallback, which sends the OMS password Base64-encoded. Lab use only.

The default, `STRICT` (also when blank), verifies the OMS certificate and host name. It replaces the two older properties *OMS: skip certificate validation* and *OMS: allow cleartext HTTP fallback*: after an upgrade, set it on any target that used them.

**Related:** [Licensing](targets-and-properties.md#licensing) · [Install and upgrade](install-and-upgrade.md#after-upgrade)

## Logs {#logs}

- **CollectorStatus** has one row per metric group: `Status`, a plain-language `Reason`, `ConsecutiveErrors`, `LastDurationMs` and `LastAttemptEpoch`. It tells an empty group from a broken one ([CollectorStatus](metrics-reference.md#collectorstatus)).
- **The plug-in log** on the agent host that monitors the target: `<agentStateDir>/ip_plugin/xdb2/logging/db2_oem.log`, rotated as `db2_oem-<date>-<n>.log`, up to 10 files of 15 MB. When the agent state directory cannot be used, the log is in the plug-in home instead, as in earlier releases ([Files the plug-in keeps on each agent](jobs-and-metric-extensions.md#agent-files)).
- **Discovery** writes the reason it skipped an instance to the agent's `emagent_perl.trc` (`<agent instance>/sysman/log/`).
- **Enterprise → Job → Activity** keeps every Kill, backup, Explain and diagnostics run, with its output.

## Known issues in this release {#known-issues}

24.1.2.0.0 / 13.5.3.0.0 has no known issue of its own. The GA known issue, Top Statements losing its SQL text after one failed lookup, is fixed. What the release deliberately does not cover is listed under [Known limitations and boundaries](whats-new.md#update-24-1-2).

## Getting support {#support}

If you need assistance with the IBM Db2 Plugin for Oracle Enterprise Manager:

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)

Include the following in your ticket, so we can reproduce what you are seeing:

- The plug-in version. Run `emcli list_plugins_on_server` and find `ip.em.xdb2` in the output.
- Your Enterprise Manager line, 13.5 or 24ai.
- Your Db2 version, 11.5 or 12.1, and the topology (single-partition, DPF or pureScale).
- The page or metric involved, and the target's **CollectorStatus** row for it.
- The Monitoring Readiness results: the note under **Check again**, and every item that is not OK.
- A screenshot of what you are seeing.

If support asks for diagnostics, run the **Collect IBM DB2 Plug-in Diagnostics** job and attach the archive it writes: see [Collect diagnostics for support](jobs-and-metric-extensions.md#collect-diagnostics).

## Related

- [Getting started](getting-started.md): the install path this page's symptoms usually trace back to
- [Monitoring pages](monitoring-pages.md#monitoring-readiness): the Monitoring Readiness page
- [Metrics reference](metrics-reference.md#collectorstatus): CollectorStatus, column by column
- [Upgrade notes](upgrade-notes.md): what changes when you upgrade from GA
- [AI troubleshooting guide](https://docs.integrationplumbers.io/db2/ai/troubleshooting.md): the same checks, for your own AI assistant
