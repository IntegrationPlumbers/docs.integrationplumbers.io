---
title: Troubleshooting
nav_order: 13
---

# Troubleshooting

The things that go wrong most often, what each one looks like, and what to change.

**In this page:** The license gate · Install and deploy · Connecting to MySQL · ClusterSet health · Jobs · Metrics that look wrong · Collections stop reaching the repository · Logs and the log level · Known issues in this release · Getting support

Nearly everything that goes wrong in the first hour with this plug-in is one of a small number of things. This page is that list rather than a general guide to Enterprise Manager.

**If a MySQL Database target is Up but its pages are empty, it is the license key.** That is the first thing to check on a new target, so it is the first section.

For a target whose pages are empty or partly filled, open its Monitoring Readiness page first: it checks the privileges, `performance_schema`, the `sys` schema, the backup history tables, the license and MySQL Shell, and shows the statement to run for each fix (see [Monitoring pages](monitoring-pages.md)). A [troubleshooting guide for AI assistants](https://docs.integrationplumbers.io/mysql/ai/troubleshooting.md) covers the same checks in a form you can load into your own assistant together with the page's results, before you raise a service request.

## 1. The license gate {#license}

**Symptom.** The target shows **Up**. Its Overview page and every metric page are empty. There is a CRITICAL incident on the `License` metric, and each metric group reports a collection error reading:

```
Collection stopped by license status: <status>
```

**Cause.** Every **MySQL Database** target needs a license key in its **License Key** property (`ip_mysql_database_license`). While the status is anything but `Active`, the plug-in stops ordinary collection on that target. Availability keeps reporting, which is why the target stays *Up* rather than going *Down*. The incident and the collection errors are the signal, not the target status.

**Fix.** Read the `Status` column of the `License` metric and act on it:

| Status | Meaning | What to do |
|---|---|---|
| `Active` | The key is genuine, issued for this plug-in, and in date | Nothing |
| `License Required` | No key has been entered | Enter your license key in the License Key property |
| `Invalid Signature` | The key text was altered | Paste the key exactly as issued, as one line, no wrapping, no trailing spaces |
| `Wrong Plug-in` | The key was issued for a different plug-in, for example a key issued for a pre-release build | Use the key issued for `ip.em.xmys` |
| `Expired` | The key's expiry date has passed | Request a new key |

The key is checked on the agent host every 15 minutes, and again as soon as the property changes. Collections resume at their next interval once the key is accepted. Nothing needs a restart.

**Not affected.** InnoDB Cluster and InnoDB ClusterSet targets are containers, not licensed targets. They are never gated and need no key.

## 2. Install and deploy {#deploy}

**`Incompatible version` at import.** The plug-in ships one artifact per Enterprise Manager line, each built with that line's development kit, and EM refuses the other one. Use `24.1.10.0.0` on EM 24ai and `13.5.10.0.0` on 13.5.

**A new release's metrics show no data.** Some releases move target metadata. When they do, the OMS side and the agent side must both be deployed. Deploy the agent side in the same maintenance window as the OMS side. Until you do, metrics added by that release have nowhere to come from and their pages stay empty while everything else keeps working. [Upgrade notes](upgrade-notes.md) lists every release that needs it.

**The OMS restarted during deployment.** Expected on releases that move target metadata. `emcli get_plugin_deployment_status -plugin=ip.em.xmys` tells you when it is back.

**`MySQL Connector/J not found: no mysql-connector-j-*.jar in <directory>; files present: ...`** Every collection on that agent, and Run EXPLAIN, reports this until the driver is in place; the target is not showing a MySQL problem. The message names the directory the plug-in looked in, `<agentStateDir>/ip_plugin/xmys/lib`, and lists what it found there. Put exactly one Connector/J jar in that directory (8.4.0 is the tested version; the prerequisites page covers later ones), readable by the agent user; the next collection uses it. If the message says the directory was missing and has been created, the agent had never had a driver staged. See [Prerequisites](prerequisites.md#29-mysql-connectorj-on-agent-hosts).

**`MySQL Connector/J: N mysql-connector-j-*.jar files in <directory> (...); keep exactly one.`** Two or more drivers were left in the directory, typically after an upgrade. Remove all but the one you mean to use.

**`MySQL Connector/J: <jar> is not usable by this plug-in - it lacks <class> ...`** The file is not a Connector/J release the plug-in can link against: a legacy `mysql-connector-java` build renamed, a corrupt download, or a release outside the tested range. Replace it with `mysql-connector-j-8.4.0.jar` and compare its SHA-256 with the value in the prerequisites.

**Collections stop after installing a newer Connector/J.** Connector/J 8.4.0 is the tested version; later 8.4.x and 9.x releases are expected to work but are not certified for this release. Go back to 8.4.0 and send us the version that failed.

**`MySQL Connector/J: cannot locate <agentStateDir>/ip_plugin/xmys/lib - agentStateDir did not resolve on this agent`.** The agent did not hand the plug-in its instance directory. Check `emctl status agent` on that agent shows an **Agent Home**, and that the plug-in was deployed to the agent after the agent was last upgraded.

**Windows agents.** Not supported in this release. The agent doing the monitoring must be Linux; the MySQL server it monitors can be anywhere it can reach.

## 3. Connecting to MySQL {#connecting}

**Target stays Down, or `Access denied` for an account you just created.** The agent connects over TCP, so the monitoring account's host clause has to match the agent's address *as MySQL sees it*, not `localhost`. An account created as `'em_monitoring'@'localhost'` will not authenticate a remote agent. See [Prerequisites](prerequisites.md#24-the-monitoring-user).

**`Access denied` even though the account exists with the right host clause.** MySQL matches the *most specific* host entry first, and an anonymous account (`''@'localhost'`, present by default in some distributions) is more specific than `'em_monitoring'@'%'` for a connection that arrives as localhost. The anonymous entry wins, authentication is attempted against it, and it fails. Check with:

```sql
SELECT user, host FROM mysql.user ORDER BY user, host;
```

If an anonymous row exists and your agent connects locally, either remove it (`DROP USER ''@'localhost';`) or connect over TCP to an address that does not match it. The error names your account while the server never tried it.

**Socket connections.** A local agent can use the Unix socket instead of TCP, which changes the host-clause rules. See [Prerequisites](prerequisites.md#26-unix-socket-connections).

**`Access denied` over a Unix socket right after `mysqld` restarted, for an account using `caching_sha2_password`.** MySQL refuses the full authentication exchange over a socket until the account's password has been cached by a login, and drops that cache on restart. This release completes the exchange itself, so a socket target recovers on its next collection with no human login. If you still see it, the driver in `ip_plugin/xmys/lib` is not the tested Connector/J release: the fix lives in the plug-in's own authentication code, which links against Connector/J 8.4.0.

**Kerberos (JDBC path) fails while the same account works from the `mysql` client.** The collections authenticate through the Java runtime's Kerberos libraries, not the system ones, so they read the credential cache and `krb5.conf` the agent's Java sees. Set the target's Kerberos Configuration File (4.1) to a file the agent user can read, keep the ticket refreshed for the agent's operating-system user, and check that the agent's Java trusts the realm's encryption types.

## 4. ClusterSet health {#clusterset}

**`health_status` reads `UNKNOWN` and `dr_promotion_ready` reads -1.** Readiness was not assessed. ClusterSet health needs **MySQL Shell** (`mysqlsh`) on the agent host, on the agent's PATH, and a connection it can use. When it cannot run, the plug-in falls back to a repository rollup or, with no data to roll up, to no assessment at all, and `fallback_reason` says why. Neither can assess promotion readiness, so the verdict is UNKNOWN rather than a pass or a fail, and the DR Promotion Ready alert does not fire. `MYSQLSH_NOT_FOUND` is a missing prerequisite, not a sick cluster: see [Prerequisites](prerequisites.md#22-mysql-shell-for-clusterset-targets). The reasons below that name a fault also raise the Fallback Reason WARNING.

**`dr_promotion_ready` reads 0 and the DR Promotion Ready alert is CRITICAL.** MySQL Shell assessed the ClusterSet and a readiness check failed: `health_status` reads `NOT_READY`. The ClusterSet DR Health page shows which one. A ClusterSet with no replica clusters reads 0 too, because there is nothing to fail over to.

**`TLS_TRUSTSTORE_REQUIRED`.** The `VERIFY_CA` and `VERIFY_IDENTITY` connection modes for ClusterSet health checks need truststore credential support, which this release does not provide. Rather than quietly downgrading to a weaker mode, the check fails closed and reports this status. `REQUIRED` and `DISABLED` modes work fully.

**`MEMBER_UNREACHABLE`.** MySQL Shell connected successfully through one of the target's listed endpoints, but then failed reaching a *different* member, `Can't connect to MySQL server on '<host>:<port>'`, while reading the ClusterSet-wide status. The AdminAPI opens its own session to every member Group Replication still considers online, regardless of which member Shell is connected through, so this can happen even when the endpoint list itself worked. 

Retrying a different listed endpoint will not fix it: the same member is unreachable either way. Open the agent host's network path to that member too. Every member of every cluster needs a path from the agent host on its MySQL port, whether or not the member is configured on the target (see [Prerequisites](prerequisites.md#23-network-and-ports)). 

The same reason is reported when MySQL Shell answers through a replica-cluster member but cannot reach any member of the primary cluster: Shell then reports the primary cluster's state as `UNKNOWN` instead of failing, and the plug-in reports readiness as not assessed rather than "not ready", because from the agent host a cut path and a primary cluster that is down look the same.

**`KERBEROS_TICKET`.** The ClusterSet target uses Kerberos, and the Kerberos exchange failed before any member saw a credential. MySQL Shell reports every such failure as no more than `Unknown MySQL error`, so the plug-in names the family for you; the usual cause is the agent operating-system user's credential cache being missing or expired, but an unreachable KDC, clock skew between the agent host and the KDC, or a member without a `mysql/<host>` service principal produce the same text. 

Start with `klist` as the agent's operating-system user on the agent host; if it shows no ticket or an expired one, restore the unattended refresh (`k5start`, or a scheduled `kinit -kt <keytab> <principal>`) described in [Prerequisites](prerequisites.md). If the ticket is fine, `kinit` and a manual `mysql --default-auth=authentication_kerberos_client` against the member will show the real error. 

Do not read the target's other collections as proof either way: MySQL Shell resolves the credential through the system Kerberos libraries and the JDBC collections through the Java runtime, which can read different caches, so one path can authenticate while the other does not.

**`KERBEROS_CLIENT_UNAVAILABLE`.** MySQL Shell on the agent host could not load its Kerberos client plug-in (`Authentication plugin 'authentication_kerberos_client' cannot be loaded`). Install the MySQL Shell package that ships its client plug-ins, and the Kerberos client libraries it links against, on the agent host; `mysqlsh --version` alone does not prove the plug-in is present.

**`KERBEROS_CONFIG_UNREADABLE`.** The Kerberos Configuration File set on the target is not readable by the agent's operating-system user, so the plug-in did not run MySQL Shell at all. MySQL Shell would otherwise fall back to `/etc/krb5.conf` silently, while the JDBC collections fail on the same path, and the two would disagree. Check the path in the target's properties and the file's permissions on the agent host.

**`KERBEROS_NOT_SUPPORTED`.** The endpoint refused the Kerberos client plug-in (`Authentication method authentication_kerberos_client is not supported`). That is what a MySQL Router port answers to MySQL Shell: Shell cannot log in with Kerberos through a Router, a MySQL limitation (the plug-in's JDBC collections can, so the rest of the target keeps collecting). Configure the ClusterSet target with member endpoints (a node list) instead of a Router port, or use password authentication for a Router-fronted target.

## 5. Jobs {#jobs}

**Run EXPLAIN fails with `Unable to get credentials for defaultHostCred`.** The job needs *two* credentials, and this error is about the second one:

- the target's **monitoring credential**, the MySQL account, which connects and asks for the plan; and
- a **Host Preferred Credential** on the target, a named host credential whose run-as is the agent's operating-system user, which lets the agent start the plug-in's program on the agent host.

The agent's own OS credential is not resolved automatically for this job type, so a named host credential is required rather than optional. Set it once per target under **Setup → Security → Preferred Credentials**: select the **MySQL Database** target type, open **Manage Preferred Credentials**, and set the host credential set to a named credential running as the agent's OS user.

**Run EXPLAIN fails with `MySQL Connector/J not found ...` or `cannot locate <agentStateDir>/ip_plugin/xmys/lib - EMSTATE is not set in the job step`.** The job runs under the target's Host Preferred Credential and reads the same driver directory as the collections. The first message means the driver is missing on that agent host or unreadable by the credential's operating-system user (the jar and the directory must be readable by it). The second means the credential switched user without keeping the agent's environment, usually a `sudo` rule with `env_reset` and no `env_keep`; allow the environment through, or use a credential that runs directly as the agent user.

**The Host Preferred Credential uses `pbrun` or another privilege-delegation tool.** This release is tested with a credential that runs directly as the agent's operating-system user and with `sudo`. PowerBroker (`pbrun`) and similar tools are untested. If you must use one, confirm that the switched user keeps the agent's environment (see the `EMSTATE` entry above) and send us the result either way.

**Run EXPLAIN fails with `the job step's javaHome=... does not name a JVM`.** The Java runtime Enterprise Manager resolved for the job is not there. This points at the agent installation rather than the plug-in; `emctl status agent` on that agent and the agent's own upgrade history are the place to look.

**Run EXPLAIN returns a syntax error on a statement copied from Query Analyzer.** Query Analyzer shows normalized digests, with literals replaced by `?`. A digest will not explain as it stands. Substitute real values for the placeholders first. See [Jobs](jobs.md#81-run-explain).

**Run EXPLAIN reports `No complete query reached the job, so nothing was explained`.** The plug-in refused the job's input rather than explain part of a statement. An `ERROR` line just above it in the job output names the reason: the input did not finish arriving within 10 seconds (a heavily loaded agent host; run the job again), or a value repeated a setting the job passes itself, which happens when the **Database Name** contains a line break. Enter the database name on one line.

**Run EXPLAIN reports `… This query starts with something else, so it was not run`.** The job explains only a `SELECT`, `WITH`, `TABLE`, `INSERT`, `REPLACE`, `UPDATE` or `DELETE` statement, or one opening with `(`, so that it never runs the statement. Remove anything before the statement other than comments, such as `ANALYZE`, a `FORMAT=` option or a `/*!` comment. See [Jobs](jobs.md#81-run-explain).

**Run EXPLAIN reports `A connection property contains a comma, which the job cannot pass`.** The target's Host, Port, Unix Socket Path, TLS Mode or Kerberos config contains a comma, usually an endpoint list. Run EXPLAIN connects to one server: give the target a single host and port.

## 6. Metrics that look wrong {#metrics}

**Query Analytics look stale on an idle server.** Like all Enterprise Manager keyed metrics, the query-digest tables retain their last collected rows when a collection window sees no new activity. The rows are not being refreshed because there is nothing to refresh them with. The `active_digest_count` column is the freshness signal. Read that before concluding a collection has stopped.

**Backup failures are not being detected.** Detection is tool-asymmetric: MySQL Enterprise Backup records failed runs, and Percona XtraBackup does not. For an XtraBackup-only estate the backup-age threshold is your failure signal, because a failed run leaves no row to find. Details in [Backup monitoring](backup-monitoring.md).

**One metric group errors on an uncertified MySQL version.** The plug-in does not block versions it has not seen. It attempts full monitoring, and where an uncertified server behaves differently the affected group degrades to a collection error on that group alone rather than taking the target down. If you hit this, report the group and the MySQL version to your Integration Plumbers support contact.

## 7. Collections stop reaching the repository {#overload}

**The 24 Hours window stops advancing, Week and Month stay empty, and `emctl status oms -details` says "PBS may not be up" while the console works.** The repository cannot absorb the metric load, usually because the agent hosting the MySQL targets shares a host with the Management Service or the repository database, or carries more targets than its cores allow. Confirm with the WebLogic server log (`[STUCK] ExecuteThread` stacks ending in `MetricLoadShared.flushRows` on a JDBC commit) and the repository's wait profile (`log file sync` in seconds). Relief and the sizing rule are in the user guide, 2.8: blackout what you can spare, restart the OMS, then spread the targets or lower the high-cardinality schedules before lifting the blackout.

## 8. Logs and the log level {#logs}

**The plug-in log.** Every collection runs as its own short Java process on the agent host that monitors the target, and all of them write to one file there:

```
<agent binaries>/plugins/ip.em.xmys.agent.plugin_<version>/logging/mysql_oem.log
```

`emctl status agent` on the agent host prints **Agent Binaries** (the `plugins` directory is under it) and **Agent Home** (the agent's own logs are under it). Each launch logs one `INFO` line naming the target type and the metric group, for example `Running with args: target=Instance category=Response`; a fault follows as `WARN` or `ERROR` with the driver's or MySQL Shell's message. A line does not name the target, so match lines to a target by time and metric group.

The file rolls over at 15 MB and the plug-in keeps ten rolled files beside it. Passwords and license keys are never written to it. A Run EXPLAIN job does not write to this file: its output, including any error, is in the job step's output on the Job Activity page.

**The agent log.** `<agent home>/sysman/log/gcagent.log` is the agent's own view: a collection that timed out, a metric evaluation error, or an upload that could not reach the OMS. Read it beside the plug-in log when a metric group shows a collection error the plug-in log does not explain.

**The OMS log.** Console pages and job dispatch run on the OMS, so an Unexpected Error dialog on a plug-in page, or a job that never reaches the agent, leaves its trace in `<OMS instance>/em/EMGC_OMS1/sysman/log/emoms.trc`. Deployment progress is in `emcli get_plugin_deployment_status -plugin=ip.em.xmys`.

**Raising the log level.** The plug-in ships a standard log4j2 configuration beside the log, at `logging/log4j2.xml` in the same plug-in directory, and the agent points every launch at it. To see more, change the root level in that file from `info` to `debug`:

```xml
<Root level="debug">
```

Each collection is a new process, so the next collection on that agent uses the new level with no restart. Set it back to `info` when you are done: a database target makes about 14 launches a minute, and each of them now logs at `debug`. The file is replaced when the plug-in is upgraded on the agent, which restores `info`.

## 9. Known issues in this release {#known-issues}

These are the known issues of release 24.1.10.0.0 and 13.5.10.0.0. The release that carries each fix is named in parentheses. None of them stops a target from collecting.

- **A MySQL role can be flagged as an over-privileged account.** The Security Accounts rules evaluate every row of `mysql.user`, and a role holding a flagged privilege is reported on the role row as well as on the account that inherits it. Read the violation on the account; the role row is the same finding. The fix marks roles and names the role on the account's violation (GA Update 1).
- **A failed Run EXPLAIN ends with the job status Succeeded.** The step output carries the `em_error` line that names the fault, preceded by a Java stack trace. The console's Explain panel reads the `em_error` line correctly; the job pages do not. Read the step output, not the job status (GA Update 1).
- **Non-ASCII characters in the monitoring password or an EXPLAIN statement.** The plug-in decodes what the agent sends it in the agent's default character set, which is ASCII under `LANG=C`. Use an ASCII password for the monitoring account, and ASCII in Run EXPLAIN statements, until the encoding is pinned (GA Update 1).
- **Cluster targets carry no quorum or fault-tolerance verdict.** A member stopped cleanly reads as the remaining members online, a cluster that lost its majority abruptly can still read Up while a member answers, and a member leaving raises no incident of its own. Check the cluster with MySQL Shell's `cluster.status()` after any member event (GA Update 1).
- **ClusterSet health that stops updating raises no incident.** The last verdict stays on the page with its Collected At time. Check that time before acting on a verdict (GA Update 1).
- **An authentication failure reads as Down.** A wrong password, a locked account or a lapsed Kerberos ticket marks the target Down like a server outage; the connection row on Monitoring Readiness shows the driver's message (GA Update 1).
- **TLS certificate verification is not available.** The `verify_ca` and `verify_identity` modes are not available in this release (2.5): ClusterSet health refuses them (`TLS_TRUSTSTORE_REQUIRED`), and the JDBC collections are not certified with them. Use `required`, which fails closed for encryption (GA Update 1).
- **MariaDB is not a supported platform.** On MariaDB 11.8, five metric groups report a collection error at every collection (ReplicationByWorker, ReplicationConnStatus, ReplicationConnectionConfig, SecurityAccounts, SecurityConfigExt) because they read MySQL-only tables. The other groups collect. MariaDB support is planned separately.
- **Managed services other than Amazon RDS are not certified.** Aurora MySQL, Google Cloud SQL and Azure Database for MySQL work as manually added targets (see 4.4 in the user guide) and are not yet certified. Amazon RDS for MySQL 8.4 is certified.
- **Tested versions.** MySQL Connector/J 8.4.0 is the tested driver; later 8.4.x and 9.x releases are expected to work and are not certified. InnoDB ClusterSet is validated on MySQL 9.5; certification on 8.4 and 9.7 LTS is planned.
- **Windows agents are not supported, and `pbrun` is untested.** The monitoring agent must run on Linux. Host Preferred Credentials are tested running directly as the agent user and through `sudo`; PowerBroker and similar tools are untested (see Jobs above).
- **EM 13.5 column widths.** On Enterprise Manager 13.5 some console tables keep the widths that Enterprise Manager's own table component gives them, rather than sizing to their content as on 24ai (GA Update 1).

## 10. Getting support {#support}

Integration Plumbers supports the plug-in directly. Write to `helpdesk@integrationplumbers.io`: every message opens a ticket and you receive the ticket reference by reply. Open and follow tickets at <https://integrationplumbers.zohodesk.com/portal/en/home>. For a suspected security vulnerability, put `SECURITY` first in the subject line. Response targets by priority are set in the support terms that accompany your license.

**What to send.** The support bundle is one archive from the agent host that monitors the target, plus two lines from the OMS. On the agent host, as the agent's operating-system user, with the two paths from `emctl status agent`:

```bash
emctl status agent > /tmp/agent-status.txt
tar czf /tmp/mysql-plugin-support-$(hostname).tgz /tmp/agent-status.txt \
    <agent binaries>/plugins/ip.em.xmys.agent.plugin_*/logging \
    <agent home>/sysman/log/gcagent.log
```

On the OMS host:

```bash
emcli list_plugins_on_server
emcli get_plugin_deployment_status -plugin=ip.em.xmys
```

Add the target's Monitoring Readiness page (every check with its status, current value and required value), the MySQL version and edition, the metric group or console page involved, and what you expected to see. The plug-in log carries no passwords or license keys; look through anything else you add and replace a secret with `<removed>` before sending. Do not send keytabs or Kerberos tickets.

---

**In short:** the license gate explains most empty pages, a missing `mysqlsh` explains most unhappy ClusterSets, and a missing host credential explains Run EXPLAIN.

If you find something that is not on this page, send it to support (section 10); this page grows from what you report.
