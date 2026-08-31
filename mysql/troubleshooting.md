---
title: Troubleshooting
nav_order: 13
---

# Troubleshooting

The things beta users actually hit, what each one looks like, and what to change.

**In this page:** The licence gate · Install and deploy · Connecting to MySQL · ClusterSet health · Jobs · Metrics that look wrong

Nearly everything that goes wrong in the first hour with this plug-in is one of a small number of things, and after a few beta deployments we know which. This page is that list rather than a general guide to Enterprise Manager.

**If a beta target is Up but its pages are empty, it is the licence key.** That single cause accounts for more first-hour reports than everything else here combined, so it is the first section.

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

**Windows agents.** Not supported in this release. The agent doing the monitoring must be Linux; the MySQL server it monitors can be anywhere it can reach.

## 3. Connecting to MySQL {#connecting}

**Target stays Down, or `Access denied` for an account you just created.** The agent connects over TCP, so the monitoring account's host clause has to match the agent's address *as MySQL sees it* — not `localhost`. An account created as `'em_monitoring'@'localhost'` will not authenticate a remote agent. See [Prerequisites](prerequisites.md#the-monitoring-user).

**`Access denied` even though the account exists with the right host clause.** MySQL matches the *most specific* host entry first, and an anonymous account (`''@'localhost'`, present by default in some distributions) is more specific than `'em_monitoring'@'%'` for a connection that arrives as localhost. The anonymous entry wins, authentication is attempted against it, and it fails. Check with:

```sql
SELECT user, host FROM mysql.user ORDER BY user, host;
```

If an anonymous row exists and your agent connects locally, either remove it (`DROP USER ''@'localhost';`) or connect over TCP to an address that does not match it. This costs people hours because the error names your account while the server never tried it.

**Socket connections.** A local agent can use the Unix socket instead of TCP, which changes the host-clause rules — see [Prerequisites](prerequisites.md#unix-socket-connections).

## 4. ClusterSet health {#clusterset}

**`dr_promotion_ready` reads 0 and the DR Promotion Ready alert is CRITICAL.** ClusterSet health needs **MySQL Shell** (`mysqlsh`) on the agent host, on the agent's PATH. Without it the plug-in falls back to a repository rollup, and the rollup cannot assess promotion readiness — so the value is 0 and the alert fires until `mysqlsh` is installed. This is a missing prerequisite, not a sick cluster. See [Prerequisites](prerequisites.md#mysql-shell-for-clusterset-targets).

**`TLS_TRUSTSTORE_REQUIRED`.** The `VERIFY_CA` and `VERIFY_IDENTITY` connection modes for ClusterSet health checks need truststore credential support, which this release does not provide. Rather than quietly downgrading to a weaker mode, the check fails closed and reports this status. `REQUIRED` and `DISABLED` modes work fully.

## 5. Jobs {#jobs}

**Run EXPLAIN fails with `Unable to get credentials for defaultHostCred`.** The job needs *two* credentials, and this error is about the second one:

- the target's **monitoring credential** — the MySQL account, which connects and asks for the plan; and
- a **Host Preferred Credential** on the target — a named host credential whose run-as is the agent's operating-system user, which lets the agent start the plug-in's program on the agent host.

The agent's own OS credential is not resolved automatically for this job type, so a named host credential is required rather than optional. Set it once per target under **Setup → Security → Preferred Credentials**: select the **MySQL Database** target type, open **Manage Preferred Credentials**, and set the host credential set to a named credential running as the agent's OS user.

**Run EXPLAIN returns a syntax error on a statement copied from Query Analyzer.** Query Analyzer shows normalized digests, with literals replaced by `?`. A digest will not explain as it stands — substitute real values for the placeholders first. See [Jobs](jobs.md#run-explain).

## 6. Metrics that look wrong {#metrics}

**Query Analytics look stale on an idle server.** Like all Enterprise Manager keyed metrics, the query-digest tables retain their last collected rows when a collection window sees no new activity. The rows are not being refreshed because there is nothing to refresh them with. The `active_digest_count` column is the freshness signal — read that before concluding a collection has stopped.

**Backup failures are not being detected.** Detection is tool-asymmetric: MySQL Enterprise Backup records failed runs, and Percona XtraBackup does not. For an XtraBackup-only estate the backup-age threshold is your failure signal, because a failed run leaves no row to find. Details in [Backup monitoring](backup-monitoring.md).

**One metric group errors on an uncertified MySQL version.** The plug-in does not block versions it has not seen. It attempts full monitoring, and where an uncertified server behaves differently the affected group degrades to a collection error on that group alone rather than taking the target down. If you hit this, tell us which group and which version — that is exactly the feedback that moves a version onto the certified list.

---

**In short:** the licence gate explains most empty pages, a missing `mysqlsh` explains most unhappy ClusterSets, and a missing host credential explains Run EXPLAIN. Those three cover the large majority of what beta users report.

If you find something that is not on this page, please send it to the beta feedback contact supplied with your download — a symptom we have not seen is more valuable to us than one we have, and this page grows from what you tell us.

That was the six areas promised at the top: licence, install and deploy, connecting, ClusterSet, jobs, and metrics that look wrong. If none of them fit, [Getting started](getting-started.md#wrong) lists what to include in a report so we can act on it quickly.
