---
title: Troubleshooting
nav_order: 13
---

# Troubleshooting

The things that go wrong most often, what each one looks like, and what to change.

**In this page:** The licence gate · Install and deploy · Connecting to MySQL · ClusterSet health · Jobs · Metrics that look wrong

Nearly everything that goes wrong in the first hour with this plug-in is one of a small number of things. This page is that list rather than a general guide to Enterprise Manager.

**If a beta target is Up but its pages are empty, it is the licence key.** That is the first thing to check on a new target, so it is the first section.

Six areas follow: the licence gate, install and deploy, connecting to MySQL, ClusterSet health, jobs, and metrics that look wrong but are not.

## 1. The licence gate {#licence}

**Symptom.** The target shows **Up**. Its home page and every metric page are empty. There is a CRITICAL incident on the `License` metric, and each metric group reports a collection error reading:

```
Collection stopped by license status: <status>
```

**Cause.** Every **MySQL Database (Beta)** target needs a beta licence key in its **License Key** property (`ip_mysql_database_license`). While the status is anything but `Active`, the plug-in stops ordinary collection on that target. Availability keeps reporting, which is why the target stays *Up* rather than going *Down* — the incident and the collection errors are the signal, not the target status.

**Fix.** Read the `Status` column of the `License` metric and act on it:

| Status | Meaning | What to do |
|---|---|---|
| `Active` | The key is genuine, issued for this plug-in, and in date | Nothing |
| `License Required` | No key has been entered | Enter your beta key in the License Key property |
| `Invalid Signature` | The key text was altered | Paste the key exactly as issued, as one line — no wrapping, no trailing spaces |
| `Wrong Plug-in` | The key was issued for a different plug-in, for example a GA key on the beta | Use the key issued for `ip.em.xmyb` |
| `Expired` | The key's expiry date has passed | Request a new key |

The key is checked on the agent host every 15 minutes, and again as soon as the property changes. Collections resume at their next interval once the key is accepted — you do not need to restart anything.

**Not affected.** InnoDB Cluster and InnoDB ClusterSet targets are containers, not licensed targets. They are never gated and need no key.

## 2. Install and deploy {#deploy}

**`Incompatible version` at import.** The beta ships one artifact per Enterprise Manager line, each built with that line's development kit, and EM refuses the other one. Use `24.1.9.N.0` on EM 24ai and `13.5.9.N.0` on 13.5.

**A new drop's metrics show no data.** Some drops move target metadata. When they do, the OMS side and the agent side must both be deployed — deploy the agent side in the same maintenance window as the OMS side. Until you do, metrics added by that drop have nowhere to come from and their pages stay empty while everything else keeps working. [Upgrade notes](install-and-upgrade.md#upgrading) lists every drop that needs it.

**The OMS restarted during deployment.** Expected on drops that move target metadata. `emcli get_plugin_deployment_status -plugin=ip.em.xmyb` tells you when it is back.

**`MySQL Connector/J not found: no mysql-connector-j-*.jar in <directory>; files present: ...`** Every collection on that agent, and Run EXPLAIN, reports this until the driver is in place; the target is not showing a MySQL problem. The message names the directory the plug-in looked in, `<agentStateDir>/ip_plugin/xmyb/lib`, and lists what it found there. Put exactly one Connector/J jar in that directory (8.4.0 is the tested version; the prerequisites page covers later ones), readable by the agent user; the next collection uses it. If the message says the directory was missing and has been created, the agent had never had a driver staged. See [Prerequisites](prerequisites.md#mysql-connectorj-on-agent-hosts).

**`MySQL Connector/J: N mysql-connector-j-*.jar files in <directory> (...); keep exactly one.`** Two or more drivers were left in the directory, typically after an upgrade. Remove all but the one you mean to use.

**`MySQL Connector/J: <jar> is not usable by this plug-in - it lacks <class> ...`** The file is not a Connector/J release the plug-in can link against: a legacy `mysql-connector-java` build renamed, a corrupt download, or a release outside the tested range. Replace it with `mysql-connector-j-8.4.0.jar` and compare its SHA-256 with the value in the prerequisites.

**Collections stop after installing a newer Connector/J.** Connector/J 8.4.0 is the tested version; later 8.4.x and 9.x releases are expected to work but are not certified for this release. Go back to 8.4.0 and send us the version that failed.

**`MySQL Connector/J: cannot locate <agentStateDir>/ip_plugin/xmyb/lib - agentStateDir did not resolve on this agent`.** The agent did not hand the plug-in its instance directory. Check `emctl status agent` on that agent shows an **Agent Home**, and that the plug-in was deployed to the agent after the agent was last upgraded.

**Windows agents.** Not supported in this release. The agent doing the monitoring must be Linux; the MySQL server it monitors can be anywhere it can reach.

## 3. Connecting to MySQL {#connecting}

**Target stays Down, or `Access denied` for an account you just created.** The agent connects over TCP, so the monitoring account's host clause has to match the agent's address *as MySQL sees it* — not `localhost`. An account created as `'em_monitoring'@'localhost'` will not authenticate a remote agent. See [Prerequisites](prerequisites.md#the-monitoring-user).

**`Access denied` even though the account exists with the right host clause.** MySQL matches the *most specific* host entry first, and an anonymous account (`''@'localhost'`, present by default in some distributions) is more specific than `'em_monitoring'@'%'` for a connection that arrives as localhost. The anonymous entry wins, authentication is attempted against it, and it fails. Check with:

```sql
SELECT user, host FROM mysql.user ORDER BY user, host;
```

If an anonymous row exists and your agent connects locally, either remove it (`DROP USER ''@'localhost';`) or connect over TCP to an address that does not match it. This costs people hours because the error names your account while the server never tried it.

**Socket connections.** A local agent can use the Unix socket instead of TCP, which changes the host-clause rules — see [Prerequisites](prerequisites.md#unix-socket-connections).

**`Access denied` over a Unix socket right after `mysqld` restarted, for an account using `caching_sha2_password`.** MySQL refuses the full authentication exchange over a socket until the account's password has been cached by a login, and drops that cache on restart. This release completes the exchange itself, so a socket target recovers on its next collection with no human login. If you still see it, the driver in `ip_plugin/xmyb/lib` is not the tested Connector/J release: the fix lives in the plug-in's own authentication code, which links against Connector/J 8.4.0.

**Kerberos (JDBC path) fails while the same account works from the `mysql` client.** The collections authenticate through the Java runtime's Kerberos libraries, not the system ones, so they read the credential cache and `krb5.conf` the agent's Java sees. Set the target's Kerberos Configuration File (4.1) to a file the agent user can read, keep the ticket refreshed for the agent's operating-system user, and check that the agent's Java trusts the realm's encryption types.

## 4. ClusterSet health {#clusterset}

**`dr_promotion_ready` reads 0 and the DR Promotion Ready alert is CRITICAL.** ClusterSet health needs **MySQL Shell** (`mysqlsh`) on the agent host, on the agent's PATH. Without it the plug-in falls back to a repository rollup, and the rollup cannot assess promotion readiness — so the value is 0 and the alert fires until `mysqlsh` is installed. This is a missing prerequisite, not a sick cluster. See [Prerequisites](prerequisites.md#mysql-shell-for-clusterset-targets).

**`TLS_TRUSTSTORE_REQUIRED`.** The `VERIFY_CA` and `VERIFY_IDENTITY` connection modes for ClusterSet health checks need truststore credential support, which this release does not provide. Rather than quietly downgrading to a weaker mode, the check fails closed and reports this status. `REQUIRED` and `DISABLED` modes work fully.

**`MEMBER_UNREACHABLE`.** MySQL Shell connected successfully through one of the target's listed endpoints, but then failed reaching a *different* member — `Can't connect to MySQL server on '<host>:<port>'` — while reading the ClusterSet-wide status. The AdminAPI opens its own session to every member Group Replication still considers online, regardless of which member Shell is connected through, so this can happen even when the endpoint list itself worked. Retrying a different listed endpoint will not fix it: the same member is unreachable either way. Open the agent host's network path to that member too — every member of every cluster needs a path from the agent host, on its MySQL port, not only the members configured on the target (see [Prerequisites](prerequisites.md#network-and-ports)).

**`KERBEROS_TICKET`.** The ClusterSet target uses Kerberos, and the Kerberos exchange failed before any member saw a credential. MySQL Shell reports every such failure as no more than `Unknown MySQL error`, so the plug-in names the family for you; the usual cause is the agent operating-system user's credential cache being missing or expired, but an unreachable KDC, clock skew between the agent host and the KDC, or a member without a `mysql/<host>` service principal produce the same text. Start with `klist` as the agent's operating-system user on the agent host; if it shows no ticket or an expired one, restore the unattended refresh (`k5start`, or a scheduled `kinit -kt <keytab> <principal>`) described in [Prerequisites](prerequisites.md). If the ticket is fine, `kinit` and a manual `mysql --default-auth=authentication_kerberos_client` against the member will show the real error. Do not read the target's other collections as proof either way: MySQL Shell resolves the credential through the system Kerberos libraries and the JDBC collections through the Java runtime, which can read different caches, so one path can authenticate while the other does not.

**`KERBEROS_CLIENT_UNAVAILABLE`.** MySQL Shell on the agent host could not load its Kerberos client plug-in (`Authentication plugin 'authentication_kerberos_client' cannot be loaded`). Install the MySQL Shell package that ships its client plug-ins, and the Kerberos client libraries it links against, on the agent host; `mysqlsh --version` alone does not prove the plug-in is present.

**`KERBEROS_CONFIG_UNREADABLE`.** The Kerberos Configuration File set on the target is not readable by the agent's operating-system user, so the plug-in did not run MySQL Shell at all. MySQL Shell would otherwise fall back to `/etc/krb5.conf` silently, while the JDBC collections fail on the same path, and the two would disagree. Check the path in the target's properties and the file's permissions on the agent host.

**`KERBEROS_NOT_SUPPORTED`.** The endpoint refused the Kerberos client plug-in (`Authentication method authentication_kerberos_client is not supported`). That is what a MySQL Router port answers: Kerberos does not pass through Router, a MySQL limitation. Configure the ClusterSet target with member endpoints (a node list) instead of a Router port, or use password authentication for a Router-fronted target.

## 5. Jobs {#jobs}

**Run EXPLAIN fails with `Unable to get credentials for defaultHostCred`.** The job needs *two* credentials, and this error is about the second one:

- the target's **monitoring credential** — the MySQL account, which connects and asks for the plan; and
- a **Host Preferred Credential** on the target — a named host credential whose run-as is the agent's operating-system user, which lets the agent start the plug-in's program on the agent host.

The agent's own OS credential is not resolved automatically for this job type, so a named host credential is required rather than optional. Set it once per target under **Setup → Security → Preferred Credentials**: select the **MySQL Database** target type, open **Manage Preferred Credentials**, and set the host credential set to a named credential running as the agent's OS user.

**Run EXPLAIN fails with `MySQL Connector/J not found ...` or `cannot locate <agentStateDir>/ip_plugin/xmyb/lib - EMSTATE is not set in the job step`.** The job runs under the target's Host Preferred Credential and reads the same driver directory as the collections. The first message means the driver is missing on that agent host or unreadable by the credential's operating-system user (the jar and the directory must be readable by it). The second means the credential switched user without keeping the agent's environment, usually a `sudo` rule with `env_reset` and no `env_keep`; allow the environment through, or use a credential that runs directly as the agent user.

**Run EXPLAIN fails with `the job step's javaHome=... does not name a JVM`.** The Java runtime Enterprise Manager resolved for the job is not there. This points at the agent installation rather than the plug-in; `emctl status agent` on that agent and the agent's own upgrade history are the place to look.

**Run EXPLAIN returns a syntax error on a statement copied from Query Analyzer.** Query Analyzer shows normalized digests, with literals replaced by `?`. A digest will not explain as it stands — substitute real values for the placeholders first. See [Jobs](jobs.md#run-explain).

## 6. Metrics that look wrong {#metrics}

**Query Analytics look stale on an idle server.** Like all Enterprise Manager keyed metrics, the query-digest tables retain their last collected rows when a collection window sees no new activity. The rows are not being refreshed because there is nothing to refresh them with. The `active_digest_count` column is the freshness signal — read that before concluding a collection has stopped.

**Backup failures are not being detected.** Detection is tool-asymmetric: MySQL Enterprise Backup records failed runs, and Percona XtraBackup does not. For an XtraBackup-only estate the backup-age threshold is your failure signal, because a failed run leaves no row to find. Details in [Backup monitoring](backup-monitoring.md).

**One metric group errors on an uncertified MySQL version.** The plug-in does not block versions it has not seen. It attempts full monitoring, and where an uncertified server behaves differently the affected group degrades to a collection error on that group alone rather than taking the target down. If you hit this, tell us which group and which version — that is exactly the feedback that moves a version onto the certified list.

---

**In short:** the licence gate explains most empty pages, a missing `mysqlsh` explains most unhappy ClusterSets, and a missing host credential explains Run EXPLAIN. Those three cover the large majority of what beta users report.

If you find something that is not on this page, please send it to the beta feedback contact supplied with your download — a symptom we have not seen is more valuable to us than one we have, and this page grows from what you tell us.

That was the six areas promised at the top: licence, install and deploy, connecting, ClusterSet, jobs, and metrics that look wrong. If none of them fit, [Getting started](getting-started.md#wrong) lists what to include in a report so we can act on it quickly.

## 7. Collections stop reaching the repository {#overload}

**The 24 Hours window stops advancing, Week and Month stay empty, and `emctl status oms -details` says "PBS may not be up" while the console works.** The repository cannot absorb the metric load, usually because the agent hosting the MySQL targets shares a host with the Management Service or the repository database, or carries more targets than its cores allow. Confirm with the WebLogic server log (`[STUCK] ExecuteThread` stacks ending in `MetricLoadShared.flushRows` on a JDBC commit) and the repository's wait profile (`log file sync` in seconds). Relief and the sizing rule are in the user guide, 2.8: blackout what you can spare, restart the OMS, then spread the targets or lower the high-cardinality schedules before lifting the blackout.
