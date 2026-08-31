---
title: Open Beta notice
nav_order: 2.5
---

# MySQL Plug-in for Oracle Enterprise Manager — Open Beta

**Pre-release notice and terms of use. Please read before installing.**

| | |
|---|---|
| Product | Integration Plumbers MySQL Plug-in for Oracle Enterprise Manager |
| Release | Open Beta — plug-in `ip.em.xmyb`, versions `24.1.9.N.0` (EM 24ai) and `13.5.9.N.0` (EM 13.5); the exact build is in `build-info.txt` beside this file |
| Beta period | From 2026-09-01 until general availability (planned for late 2026); beta licence keys expire 2026-11-30 |
| Intended use | Evaluation in non-production Enterprise Manager environments |
| Reference | [MySQL plug-in User Guide](index.md) — the authoritative description of what the plug-in does |

## 1. What this release is

This is a **pre-release build** of the plug-in, made available so that you can run it against real MySQL estates, judge it critically, and tell us what you find before general availability. Every metric family, threshold, compliance standard and console page in it has been deployed and exercised against live MySQL targets in our lab; what a beta cannot have yet is the breadth of validation that only other people's environments provide.

The beta is a **separate plug-in from the GA release**, by design:

| | Open Beta | General availability |
|---|---|---|
| Plug-in ID | `ip.em.xmyb` | `ip.em.xmys` |
| Target types | `ip_mysql_database_beta`, `ip_mysql_cluster_beta`, `ip_mysql_clusterset_beta` — shown as *MySQL Database (Beta)* etc. | `ip_mysql_database`, `ip_mysql_cluster`, `ip_mysql_clusterset` |
| Versions | `24.1.9.N.0` / `13.5.9.N.0` (N = beta drop) | `24.1.1.1.0` / `13.5.1.1.0` onward |
| Licence keys | Issued for `ip.em.xmyb`; expire 2026-11-30 | Issued for `ip.em.xmys` |

- **Beta to beta:** later beta drops upgrade in place (see 4.5).
- **Beta to GA is a clean install.** GA is a different plug-in with different target types. Nothing the beta created in your Management Repository — targets, metric history, incidents, thresholds you tuned — carries into GA, and a beta install remains identifiable as such in any audit. Plan the GA rollout as a fresh deployment alongside, then retire the beta.

## 2. Terms of use — installing means you accept

> **Integration Plumbers MySQL Plug-in for Oracle Enterprise Manager — Open Beta**
>
> This is a pre-release (beta) build provided for evaluation. **By installing, deploying or using it you accept the following:**
>
> 1. **Not for production.** Deploy it to a non-production Enterprise Manager and monitor non-critical MySQL servers. Do not use it for production monitoring, for compliance-of-record, or as the basis for operational decisions about production systems until the general-availability release.
> 2. **No warranty and no service level.** The software is provided "as is". There is no guarantee of availability, accuracy, fitness for a particular purpose, response time or resolution. Integration Plumbers is not liable for loss, damage or cost arising from its use during the beta.
> 3. **Behaviour may change.** Metric names, collection intervals, default thresholds, compliance rules and console pages may change between beta drops and before GA. Changes that need action on your side are recorded in [upgrade notes](upgrade-notes.md).
> 4. **Support is best effort.** Findings are handled through the beta feedback contact supplied with your download, on a best-effort basis during business days — not through a production support queue (section 6).
> 5. **Licensed for the beta only.** Beta licence keys are issued for the beta plug-in, expire on 2026-11-30, and do not license the GA release. The plug-in reads the key locally on the agent host; it sends nothing outside your Enterprise Manager installation.
> 6. **Your environment, your data.** You are responsible for the credentials you grant the plug-in (a read-only monitoring account is all it needs — User Guide 2.4) and for the systems you point it at.
>
> If you do not accept these terms, do not install the software.

## 3. Before you install

- **Enterprise Manager 24ai (24.1) or 13.5.** The beta ships one artifact per EM line, each built with that line's development kit; EM refuses the other one at import (`Incompatible version`). Use the artifact that matches your OMS.
- **A Linux Management Agent** on, or with network reach to, each MySQL server. Windows agents are not supported in this release.
- **A monitoring account** on each MySQL server with `SELECT`, `PROCESS` and `REPLICATION CLIENT` — the exact grants, and the optional backup-catalog grants, are in User Guide 2.4.
- **MySQL Shell (`mysqlsh`) on the agent host** if you will monitor InnoDB ClusterSets; without it ClusterSet health falls back to a repository rollup that cannot assess DR promotion readiness (section 5).
- **Network:** the agent reaches each server's MySQL port (default 3306), or its Unix socket for a local agent (User Guide 2.3, 2.6).
- **A beta licence key** for `ip.em.xmyb`, one per licensed MySQL Database target, from your Integration Plumbers contact.

## 4. Installing the beta

The steps are the standard plug-in lifecycle; User Guide chapter 3 has the full procedure and screenshots. In brief:

### 4.1 Import the plug-in
Copy the OPAR for your EM line to the OMS host and import it:

```
emcli login -username=<em administrator>
emcli import_update -file=/tmp/<artifact>.opar -omslocal
```

### 4.2 Deploy to the OMS, then to the agents
```
emcli deploy_plugin_on_server -plugin=ip.em.xmyb            # EM 24ai prompts for the repository SYS/ADMIN password; on 13.5 pass -sys_password
emcli get_plugin_deployment_status -plugin=ip.em.xmyb       # wait for Success
emcli deploy_plugin_on_agent -plugin=ip.em.xmyb -agent_names="<agent host>:<port>"
```
Some drops move target metadata, in which case the OMS deployment restarts the OMS; the status command tells you when it is back.

### 4.3 Add a MySQL Database (Beta) target
In the console, *Setup → Add Target → Add Targets Manually*, choose the **MySQL Database (Beta)** type, and fill in host, port, the monitoring credentials and the **License Key**. Include "(Beta)" in the target name — auto-discovered beta targets get that suffix automatically — so beta and GA targets never share a name in All Targets or notifications. With emcli:

```
emcli add_target -name="<server> (Beta)" -type=ip_mysql_database_beta -host=<agent host> \
  -properties="ip_mysql_database_host:<mysql host>;ip_mysql_database_port:3306;ip_mysql_database_license:<key>" \
  -credentials="ip_mysql_database_username:<user>;ip_mysql_database_password:<password>"
```

### 4.4 Verify the first collection
Within a few minutes the target shows **Up**, its home page fills in, and the **License** metric reports `Active`. If the `License` status is anything else, section 7 explains what it means and what to change.

### 4.5 Moving between beta drops
Import the new drop and deploy it on the OMS and then on the agents (4.1–4.2); targets and their history are kept. When a drop changes target metadata, deploy the agent side in the same maintenance window as the OMS side — until then that target's new metrics show no data. [upgrade notes](upgrade-notes.md) lists every drop that needs this.

### 4.6 Removing the beta
Undeploy from the agents (`emcli undeploy_plugin_from_agent -plugin=ip.em.xmyb -agent_names=... -delete_targets`), then from the OMS (`emcli undeploy_plugin_from_server -plugin=ip.em.xmyb`). GA is installed fresh (section 1).

## 5. What is verified, and known limitations

### Certification matrix (as of this release)

| Target | Tier | Status |
|---|---|---|
| MySQL 8.4 LTS | Comprehensive | **Certified** — primary reference platform |
| MySQL 9.7 LTS | Comprehensive | **Certified** (2026-07-28) |
| MySQL 8.0 | Basic | Supported and continuously exercised in our lab. Note 8.0 reached end of life in April 2026 — plan your upgrade |
| MySQL 9.5 / 9.6 / 26.x innovation releases | — | Expected to work; not yet certified |
| InnoDB Cluster (Group Replication, 8.4) | — | **Certified** (cluster target with member stats) |
| InnoDB ClusterSet | — | Validated on MySQL 9.5 commercial; 8.4 ClusterSet not yet certified |
| RDS / Aurora / Cloud SQL | — | Supported — added manually, see 4.4; not yet certified |
| EM 24ai (24.1) | — | **Certified**, including the UI |
| EM 13.5 | — | Collection + compliance certified; console home and chart pages verified on `13.5.9.34.0` (2026-08-25); the 13.5 edition (`13.5.9.N.0`) is built from the same source and available with the beta |

**The plug-in does not block MySQL versions it has not seen.** MySQL releases are, in our experience, backward compatible for monitoring purposes, so a newer server than the matrix above is expected to work: the plug-in attempts full monitoring, and if an uncertified version misbehaves, individual metric groups degrade to collection errors on that group without taking monitoring down as a whole. We certify versions as we validate them, prioritising LTS releases.

### Known limitations

1. **ClusterSet TLS verify modes fail closed.** `VERIFY_CA` / `VERIFY_IDENTITY` connection modes for ClusterSet health checks require truststore credential support, planned for a later release; until then those modes report `TLS_TRUSTSTORE_REQUIRED` rather than silently downgrading security. `REQUIRED` and `DISABLED` modes work fully.
2. **ClusterSet health requires MySQL Shell on the agent host** (`mysqlsh` on the agent's PATH). Without it, ClusterSet targets fall back to repository-rollup health — and the rollup cannot assess promotion readiness, so `dr_promotion_ready` reads 0 and the DR Promotion Ready alert raises CRITICAL until `mysqlsh` is installed.
3. **Query Analytics freshness on idle servers.** Like all EM keyed metrics, the query-digest tables retain their last collected rows when a collection window has no new activity; the `active_digest_count` column is the freshness signal. The statement-digest overflow row (`DIGEST IS NULL`) handling is implemented but has not been observed live in validation.
4. **Backup failure detection is tool-asymmetric.** MySQL Enterprise Backup records failed runs; Percona XtraBackup does not, so for XtraBackup-only estates the backup-age threshold is the failure signal. Details and the optional scoped grants: [backup monitoring](backup-monitoring.md).

## 6. Feedback and support during the beta

The beta exists for your findings: bugs, metrics that look wrong or differ from what your previous tooling reported, thresholds that fire when they should not (or stay quiet when they should fire), console pages that render badly in your browser, unclear documentation. Send them to the **beta feedback contact supplied with your download**. Include the plug-in version (`emcli list_plugins_on_server`), your EM version (24ai or 13.5), the MySQL version and edition, the metric group or page involved, and any deploy log, agent log or collection-error text.

Support during the beta is **best effort, during business days, with no service level**: we read everything, fix what we can in the next drop, and tell you when we cannot. Findings feed directly into GA certification.

## 7. Licensing during the beta

Every **MySQL Database (Beta)** target needs a beta licence key in its **License Key** property (`ip_mysql_database_license`). InnoDB Cluster and ClusterSet targets are containers, not licensed targets, and need no key. The plug-in checks the key on the agent host every 15 minutes — and again as soon as the property changes — and reports the result in the target's **License** metric:

| Status | Meaning | What to do |
|---|---|---|
| `Active` | The key is genuine, issued for this plug-in, and in date | Nothing |
| `License Required` | No key has been entered | Enter your beta key in the License Key property |
| `Invalid Signature` | The key text was altered | Paste the key exactly as issued, as one line |
| `Wrong Plug-in` | The key was issued for a different plug-in (for example a GA key on the beta) | Use the key issued for `ip.em.xmyb` |
| `Expired` | The key's expiry date has passed | Request a new key |

**While the status is anything but `Active`, the beta enforces the licence:** the target raises a CRITICAL incident on the `License` metric, and every other metric group on that target reports a collection error — `Collection stopped by license status: <status>` — until a valid key is entered. Availability monitoring continues, so the target shows *Up* rather than *Down*; the incident and the collection errors are the signal. Collections resume at their next interval once the key is accepted.

---

*Open Beta build. Not for production monitoring or compliance-of-record. See section 2.*
