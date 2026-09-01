---
title: Open Beta notice
nav_order: 2.5
---

# IBM Db2 Plug-in for Oracle Enterprise Manager — Open Beta

**Pre-release notice and terms of use. Please read before installing.**

| | |
|---|---|
| Product | Integration Plumbers IBM Db2 Plug-in for Oracle Enterprise Manager |
| Release | Open Beta — plug-in `ip.em.xdbb`, versions `24.1.9.N.0` (EM 24ai) and `13.5.9.N.0` (EM 13.5); the current drop is `24.1.9.9.0` / `13.5.9.4.0` |
| Beta period | From 2026-09-01 until general availability (expected late 2026); beta licence keys expire 2026-10-31 |
| Intended use | Evaluation in non-production Enterprise Manager environments |
| Reference | [IBM Db2 plug-in User Guide](index.md) — the authoritative description of what the plug-in does |

## 1. What this release is

This is a **pre-release build** of the plug-in, made available so that you can run it against real Db2 estates, judge it critically, and tell us what you find before general availability. Every metric group, threshold, compliance standard and console page in it has been deployed and exercised against live Db2 databases in our lab; what a beta cannot have yet is the breadth of validation that only other people's environments provide.

The beta is a **separate plug-in from the GA release**, by design:

| | Open Beta | General availability |
|---|---|---|
| Plug-in ID | `ip.em.xdbb` | `ip.em.xdb2` |
| Target type | `ip_db2_database_beta` — shown as *IBM DB2 Database (Beta)* | `ip_db2_database` |
| Versions | `24.1.9.N.0` / `13.5.9.N.0` (N = beta drop) | `24.1.<n>.0.0` |
| Licence keys | Issued for `ip.em.xdbb`; expire 2026-10-31 | Issued for `ip.em.xdb2` |

- **Beta to beta upgrades in place**, within the beta line — see [Install and upgrade](install-and-upgrade.md#upgrade).
- **Beta to GA is a clean install.** GA is a different plug-in with a different target type. Nothing the beta created in your Management Repository — targets, metric history, incidents, thresholds you tuned — carries into GA, and a beta install remains identifiable as such in any audit. Plan the GA rollout as a fresh deployment alongside, then retire the beta.

## 2. Terms of use — installing means you accept

> **Integration Plumbers IBM Db2 Plug-in for Oracle Enterprise Manager — Open Beta**
>
> This is a pre-release (beta) build provided for evaluation. **By installing, deploying or using it you accept the following:**
>
> 1. **Not for production.** Deploy it to a non-production Enterprise Manager and monitor non-critical Db2 databases. Do not use it for production monitoring, for compliance-of-record, or as the basis for operational decisions about production systems until the general-availability release.
> 2. **No warranty and no service level.** The software is provided "as is". There is no guarantee of availability, accuracy, fitness for a particular purpose, response time or resolution. Integration Plumbers is not liable for loss, damage or cost arising from its use during the beta.
> 3. **Behaviour may change.** Metric names, collection intervals, default thresholds, compliance standards and console pages may change between beta drops and before GA. Changes that need action on your side are recorded in the [changelog](changelog.md).
> 4. **Support is best effort.** Findings go to **helpdesk@integrationplumbers.io** — every email opens a ticket you can follow in the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/home) — and are handled on a best-effort basis during business days, not through a production support queue (section 6).
> 5. **Licensed for the beta only.** Beta licence keys are issued for the beta plug-in, expire on 2026-10-31, and do not license the GA release. For a key with an instance limit, the licence check confirms your instance count with the OMS as part of validating the key.
> 6. **Your environment, your data.** You are responsible for the credentials you grant the plug-in (a read-only monitoring user is all it needs — [The monitoring role](prerequisites.md#monitoring-role)) and for the systems you point it at.
>
> If you do not accept these terms, do not install the software.

## 3. Before you install

- **Enterprise Manager 24ai (24.1) or 13.5.** The beta ships one artifact per EM line, each built with that line's development kit; EM refuses the other one at import (`Incompatible version`). Use the artifact that matches your OMS.
- **A Linux x86-64 or Windows x86-64 Management Agent** on, or with network reach to, each Db2 server.
- **A monitoring user** on each Db2 database with `CONNECT` and `SQLADM` at database scope — the exact grants are in [The monitoring role](prerequisites.md#monitoring-role).
- **Network:** the agent reaches each database on its Db2 listener port, by default `50000` — see [Network and ports](prerequisites.md#network).
- **A beta licence key** for `ip.em.xdbb`, one per licensed IBM DB2 Database target, from your Integration Plumbers contact.

## 4. Installing the beta

The steps are the standard plug-in lifecycle; [Install and upgrade](install-and-upgrade.md) has the full procedure. In brief:

### 4.1 Import the plug-in
```
emcli login -username=<em administrator>
emcli import_update -file=/tmp/<artifact>.opar -omslocal
```

### 4.2 Deploy to the OMS, then to the agents
```
emcli deploy_plugin_on_server -plugin=ip.em.xdbb:24.1.9.9.0 -dbUser=SYS -dbPassword=<repository password>
emcli get_plugin_deployment_status -plugin=ip.em.xdbb       # wait for Success
emcli deploy_plugin_on_agent -plugin=ip.em.xdbb:24.1.9.9.0 -agent_names="<agent host>:<port>"
```

Use `13.5.9.4.0` in place of `24.1.9.9.0`, and `-sys_password=<repository password>` in place of `-dbUser`/`-dbPassword`, on Enterprise Manager 13.5. **Always pin the `:version`** on both commands — without it, a redeploy of the same or a lower version is silently skipped as "already deployed".

### 4.3 Add an IBM DB2 Database (Beta) target
In the console, *Setup → Add Target → Add Targets Manually*, choose the **IBM DB2 Database (Beta)** type, and fill in the database name, host, port, the monitoring credentials and the **Plugin Licence Key**. With emcli:

```
emcli add_target -name="<target name>" -type="ip_db2_database_beta" -host="<agent host>" \
  -properties="ip_db2_database_dbname:<DBNAME>;ip_db2_database_host:<db host>;ip_db2_database_port:50000;ip_db2_database_license:<key>" \
  -subseparator="properties=:" \
  -monitor_creds="ip_db2_database_beta:DB2DatabaseMonitoringCreds:DB2Username=<user>;DB2Password=<pwd>"
```

### 4.4 Verify the first collection
Within a few minutes the target shows **Up**, its Home page fills in, and the **License** metric reports `Active`. If the `License` status is anything else, section 7 explains what it means and what to change.

### 4.5 Moving between beta drops
Beta-to-beta upgrades in place: import the new drop's OPAR and deploy it the same way as the first install (4.1–4.2), over the existing plug-in — targets, their credentials and their collected history are kept. Pin the `:version` on both the server and agent deploy commands, or the redeploy is silently skipped. Run, or schedule, **Purge Stale Plugin Cache** once per agent after every upgrade — see [Jobs](jobs-and-metric-extensions.md#purge-stale-cache).

### 4.6 Removing the beta
Remove every **IBM DB2 Database (Beta)** target first, then undeploy from the agents (`emcli undeploy_plugin_from_agent -plugin=ip.em.xdbb -agent_names=...`), then from the OMS (`emcli undeploy_plugin_from_server -plugin=ip.em.xdbb -dbUser=SYS -dbPassword=<repository password>`, or `-sys_password=...` on EM 13.5). GA is installed fresh (section 1). Full steps, including the Self Update cleanup: [Install and upgrade](install-and-upgrade.md#uninstall).

## 5. What is verified, and known limitations

### Certification matrix (as of this release)

| Area | Status |
|---|---|
| Db2 LUW 12.1, on EM 24ai | **Certified** — deployment, collection, the credential model, licensing and the console pages verified against a live instance |
| Db2 LUW 11.5 | Supported by design; a full live collection run has not yet been completed — see [What's new](whats-new.md#beta-status) |
| HADR standby pair | **Certified in PEER state** against a live primary+standby pair; a controlled takeover/failover exercise has not yet been exercised — see [HADR monitoring](hadr-monitoring.md#known-limitation) |
| Amazon RDS for Db2 | **Documentation-verified only** — see [Troubleshooting](troubleshooting.md#rds-for-db2) |
| EM 24ai (24.1) | **Certified**, including the console |
| EM 13.5 | Offline build validation passed; not yet exercised through live deploy and console verification the way 24ai has — treat 24ai as the reference platform until 13.5 catches up |

**Db2 LUW versions below 11.5 (9.1–10.5) are not supported by this release** — see [Supported versions and platforms](prerequisites.md#supported-versions).

### What is not yet verified

- **Live Db2 11.5 collection.** Supported by design; certification against a live 11.5 instance is in progress.
- **The Enterprise Manager 13.5 line.** The `13.5.9.4.0` build passes full validation against the 13.5 development kit but has not yet been through the live-deploy and console verification given to 24ai.
- **An HADR takeover/failover exercise.** PEER-state monitoring is certified against a live pair; a controlled takeover has not yet been exercised.
- **Amazon RDS for Db2.** Compatibility is documentation-verified only, not lab-certified — see [Troubleshooting](troubleshooting.md#rds-for-db2).

### Known limitations

1. **Amazon RDS for Db2 is documentation-only in this release.** On RDS the five local administrative jobs and diagnostic-log monitoring are unavailable, because the agent cannot be co-located with the instance. All JDBC-based metric collection continues to work over the network. See [Troubleshooting](troubleshooting.md#rds-for-db2).
2. **SQL workload analytics are numeric-only.** Top-SQL trends are keyed by a statement-ID hash and carry CPU-time and execution-count trends; statement text is not collected in this release.
3. **Local-only features need a co-located agent.** Diagnostic-log monitoring and the five administrative jobs (startup, shutdown, quiesce, unquiesce, kill application) require the agent to be on the same host as the Db2 instance — see [Network and ports](prerequisites.md#network).
4. **Out of scope for this release:** Workload Management (WLM), lock/deadlock event capture, BLU/columnar, pureScale, AI Query Optimizer monitoring, Q Replication, auto-discovery, remote administrative operations, and Db2 for z/OS.

## 6. Feedback and support during the beta {#reporting}

The beta exists for your findings: bugs, metrics that look wrong or differ from what your previous tooling reported, thresholds that fire when they should not (or stay quiet when they should fire), console pages that render badly in your browser, unclear documentation. Send them to **helpdesk@integrationplumbers.io** — every email opens a ticket you can follow in the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/home), or open the ticket there directly. Include the plug-in version (`emcli list_plugins_on_server`), your EM version (24ai or 13.5), the Db2 version (11.5 or 12.1), the metric group or page involved, and any deploy log, agent log or collection-error text.

Support during the beta is **best effort, during business days, with no service level**: we read everything, fix what we can in the next drop, and tell you when we cannot. Findings feed directly into GA certification.

## 7. Licensing during the beta {#licensing}

Every **IBM DB2 Database (Beta)** target needs a beta licence key in its **Plugin Licence Key** property (`ip_db2_database_license`). The plug-in checks the key on the agent host every 15 minutes — and again as soon as the property changes — and reports the result in the target's **License** metric:

| Status | Meaning | What to do |
|---|---|---|
| `Active` | The key is genuine, issued for `ip.em.xdbb`, and in date | Nothing |
| `License Required` | No key has been entered | Enter your beta key in the Plugin Licence Key property |
| `Invalid Signature` | The key text was altered, or it was issued for a different plug-in identity | Paste the key exactly as issued, as one line, or request a key issued for `ip.em.xdbb` |
| `Expired` | The key's expiry date has passed | Request a new key |
| `Exceeded Limit` | More `ip_db2_database_beta` targets exist than the key's instance count. Only this plug-in's own targets count | Request an increased instance count, or remove a target |

For a key that carries an instance limit, checking the count means the plug-in calling the OMS to ask how many `ip_db2_database_beta` targets exist. That connection validates the OMS certificate by default; if it cannot complete, see [Troubleshooting](troubleshooting.md#oms-licence-count). An `Unlimited` licence key never contacts the OMS at all.

**While the status is anything but `Active`, the plug-in stops ordinary collection on that target.** Every metric group except **License**, **Response** and **Version** reports a collection error reading `Collection stopped by license status: <status>`, and a CRITICAL incident is raised on the `License` metric. Availability keeps reporting through **Response**, which is why the target stays *Up* rather than going *Down* — the incident and the collection errors are the signal. Collections resume at their next interval once a valid key is accepted.

---

*Open Beta build. Not for production monitoring or compliance-of-record. See section 2.*
