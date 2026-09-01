---
title: Open Beta notice
nav_order: 3
---

# SQL Server Plug-in for Oracle Enterprise Manager — Open Beta

**Pre-release notice and terms of use. Please read before installing.**

| | |
|---|---|
| Product | Integration Plumbers SQL Server Plug-in for Oracle Enterprise Manager |
| Release | Open Beta — plug-in `ip.em.xmsb`, versions `24.1.9.N.0` (EM 24ai) and `13.5.9.N.0` (EM 13.5); the current drop is `24.1.9.12.0` / `13.5.9.12.0` |
| Beta period | From 2026-09-01 until general availability (expected late 2026); beta licence keys expire 2026-10-31 |
| Intended use | Evaluation in non-production Enterprise Manager environments |
| Reference | [SQL Server plug-in User Guide](index.md) — the authoritative description of what the plug-in does |

## 1. What this release is

This is a **pre-release build** of the plug-in, made available so that you can run it against real SQL Server estates, judge it critically, and tell us what you find before general availability. Every metric group, threshold, compliance rule and console page in it has been deployed and exercised against live SQL Server instances in our lab; what a beta cannot have yet is the breadth of validation that only other people's environments provide.

The beta is a **separate plug-in from the GA release**, by design:

| | Open Beta | General availability |
|---|---|---|
| Plug-in ID | `ip.em.xmsb` | `ip.em.xmss` |
| Target type | `ip_mssql_database_beta` — shown as *SQL Server Database (Beta)* | `ip_mssql_database` |
| Versions | `24.1.9.N.0` / `13.5.9.N.0` (N = beta drop) | `24.1.1.1.0` / `13.5.1.1.0` onward |
| Licence keys | Issued for `ip.em.xmsb`; expire 2026-10-31 | Issued for `ip.em.xmss` |

- **Beta to beta:** this is the first beta drop, with no earlier build to upgrade from, and there is no supported in-place upgrade between beta drops yet — each drop is imported and deployed as a fresh install. See [Install and upgrade](install-and-upgrade.md#upgrading).
- **Beta to GA is a clean install.** GA is a different plug-in with a different target type. Nothing the beta created in your Management Repository — targets, metric history, incidents, thresholds you tuned — carries into GA, and a beta install remains identifiable as such in any audit. Plan the GA rollout as a fresh deployment alongside, then retire the beta.

## 2. Terms of use — installing means you accept

> **Integration Plumbers SQL Server Plug-in for Oracle Enterprise Manager — Open Beta**
>
> This is a pre-release (beta) build provided for evaluation. **By installing, deploying or using it you accept the following:**
>
> 1. **Not for production.** Deploy it to a non-production Enterprise Manager and monitor non-critical SQL Server servers. Do not use it for production monitoring, for compliance-of-record, or as the basis for operational decisions about production systems until the general-availability release.
> 2. **No warranty and no service level.** The software is provided "as is". There is no guarantee of availability, accuracy, fitness for a particular purpose, response time or resolution. Integration Plumbers is not liable for loss, damage or cost arising from its use during the beta.
> 3. **Behaviour may change.** Metric names, collection intervals, default thresholds, compliance rules and console pages may change between beta drops and before GA. Changes that need action on your side are recorded in [What's new](whats-new.md).
> 4. **Support is best effort.** Findings go to **helpdesk@integrationplumbers.io** — every email opens a ticket you can follow in the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/home) — and are handled on a best-effort basis during business days, not through a production support queue (section 6).
> 5. **Licensed for the beta only.** Beta licence keys are issued for the beta plug-in, expire on 2026-10-31, and do not license the GA release.
> 6. **Your environment, your data.** You are responsible for the credentials you grant the plug-in (a read-only monitoring login is all it needs — [Credentials](credentials.md#grants)) and for the systems you point it at.
>
> If you do not accept these terms, do not install the software.

## 3. Before you install

- **Enterprise Manager 24ai (24.1) or 13.5.** The beta ships one artifact per EM line, each built for that line; EM refuses the other one at import (`Incompatible version`). Use the artifact that matches your OMS.
- **A Linux or Windows Management Agent** on, or with network reach to, each SQL Server instance.
- **A monitoring login** on each instance with `VIEW SERVER STATE`, `VIEW ANY DATABASE`, `VIEW ANY DEFINITION` and `CONNECT ANY DATABASE` at server scope, plus `db_datareader` and `SQLAgentReaderRole` in `msdb` — the exact grants are in [Credentials](credentials.md#grants).
- **Network:** the agent reaches each instance on its TCP port, by default 1433 — see [Prerequisites](prerequisites.md#network).
- **A beta licence key** for `ip.em.xmsb`, one per licensed SQL Server Database target, from your Integration Plumbers contact.

## 4. Installing the beta

The steps are the standard plug-in lifecycle; [Install and upgrade](install-and-upgrade.md) has the full procedure. In brief:

### 4.1 Import the plug-in
```
emcli login -username=<em administrator>
emcli import_update -file=/tmp/<artifact>.opar -omslocal
```

### 4.2 Deploy to the OMS, then to the agents
```
emcli deploy_plugin_on_server -plugin=ip.em.xmsb -sys_password=<repository password>
emcli get_plugin_deployment_status -plugin=ip.em.xmsb       # wait for Success
emcli deploy_plugin_on_agent -plugin=ip.em.xmsb -agent_names="<agent host>:<port>"
```

### 4.3 Add a SQL Server Database (Beta) target
In the console, *Setup → Add Target → Add Targets Manually*, choose the **SQL Server Database (Beta)** type, and fill in host, port, instance name (if the instance is named), TLS mode and the **License Key**. With emcli:

```
emcli add_target -name="<target name>" -type="ip_mssql_database_beta" -host="<agent host>" \
  -properties="<host>;<port>;<instance>;<tls mode>;<license key>"
```

**Apply the monitoring credentials afterwards, not inline with this command** — passing them inline is silently ignored by this plug-in. See [Credentials](credentials.md#applying) for the `set_monitoring_credential` step.

### 4.4 Verify the first collection
Within a few minutes the target shows **Up**, its Overview page fills in, and the **License** metric reports `Active`. If the `License` status is anything else, section 7 explains what it means and what to change.

### 4.5 Moving between beta drops
There is no earlier beta build yet, so every install today is a first install (4.1–4.3). One thing worth knowing ahead of a future drop: a drop that adds a new target property does not add it to targets created on an earlier drop — only a target added after the property exists offers it. If a later drop's release notes call out a new property you need, remove and re-add the affected targets, or set the property the next time you re-onboard them.

### 4.6 Removing the beta
Undeploy from the agents (`emcli undeploy_plugin_from_agent -plugin=ip.em.xmsb -agent_names=... -delete_targets`), then from the OMS (`emcli undeploy_plugin_from_server -plugin=ip.em.xmsb -sys_password=<repository password>`). GA is installed fresh (section 1).

## 5. What is verified, and known limitations

### Certification matrix (as of this release)

| Area | Status |
|---|---|
| SQL Server 2016 – 2025, on EM 24ai | **Certified** — deployment, collection, the credential model and the console pages verified against a live instance of every declared version |
| SQL Server 2016 and 2017 | Certified, with two metric families returning less detail than 2019 and later — see [Prerequisites](prerequisites.md#supported-versions) |
| Availability groups | **Certified**, including failover readiness against a live group |
| Windows Integrated Authentication | Supported on a Windows agent, but not exercised in our lab. SQL authentication is fully exercised on both platforms |
| EM 24ai (24.1) | **Certified**, including the console |
| EM 13.5 | Import, deployment, collection and console rendering verified on a live 13.5 OMS; not yet exercised across the full SQL Server version matrix on that line — see [What is not yet verified](#not-verified) below |

**The plug-in does not block a SQL Server version it has not declared.** We certify the versions in the matrix above; a version outside it is not a supported configuration for this release.

### What is not yet verified {#not-verified}

- **The Enterprise Manager 13.5 edition across the full SQL Server version matrix.** The 13.5 build imports, deploys to the OMS and to agents, collects, and renders its console pages, verified on a live 13.5 OMS. It has not yet been exercised across SQL Server 2016 through 2025 the way the 24ai edition has — treat 24ai as the reference platform on this point until 13.5 catches up.
- **Windows Integrated Authentication.** Supported on a Windows agent, but not exercised in our lab.
- **Scale.** The largest instance tested holds a normal developer database count. Behaviour and collection overhead at a hundred or more databases on one instance is not yet measured.
- **Upgrade between beta drops.** There is no supported in-place upgrade during the beta yet — see [Install and upgrade](install-and-upgrade.md#upgrading).

### Known limitations

1. **A backup job can report Succeeded after a late failure.** If a backup or restore fails partway through, after the operation has started, the job can return without raising an error and report Succeeded while leaving an incomplete file. Failures that occur before the operation starts, such as a missing database or a permission refusal, report correctly. Confirm backup files exist and are the expected size rather than relying on job status alone.
2. **Two metric families return less detail on SQL Server 2016 and 2017**, both because the view that classifies a latched page by type arrived in 2019. TempDB contention collects, but its allocation-page and metadata-page waiter counts read zero and the advice cell is blank. Cluster nodes collects node names, but status, status description and current owner are blank. Read a zero or a blank in either as "not classifiable on this version", not as "nothing to report".
3. **Volume free space collapses on Linux.** On Linux targets the Volume Free Space region on the Analysis page can report a single row with blank volume and label cells.
4. **Windows-only surfaces are empty on Linux.** Registry settings and Windows service state have no Linux equivalent and report empty there rather than erroring.
5. **Long chart windows can under-report.** On the Week and Month chart windows on the Performance page, a period containing a missed collection can render a lower value than actually occurred, or drop a series for that period. The 24 Hours window is unaffected.
6. **Two Performance page charts do not offer a Real Time window.** Those values are measured over the collection interval, and a real-time poll would change what the scheduled collection records, so the window is not offered there.
7. **Large instances are unmeasured.** The largest instance in our lab holds a normal developer database count. Collection overhead on an instance hosting a hundred or more databases has not been characterised.
8. **Some wide tables clip their rightmost columns** at narrower browser widths.
9. **A new target looks sparse on its first day.** Server configuration and per-database space are on a 24 hour collection schedule. Most other data arrives far sooner: availability every minute, instance status every five, licence and backup age hourly. See [Monitoring pages](monitoring-pages.md#blank).

## 6. Feedback and support during the beta {#reporting}

The beta exists for your findings: bugs, metrics that look wrong or differ from what your previous tooling reported, thresholds that fire when they should not (or stay quiet when they should fire), console pages that render badly in your browser, unclear documentation. Send them to **helpdesk@integrationplumbers.io** — every email opens a ticket you can follow in the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/home), or open the ticket there directly. Include the plug-in version (`emcli list_plugins_on_server`), your EM version (24ai or 13.5), the SQL Server version and edition, the metric group or page involved, and any deploy log, agent log or collection-error text.

Support during the beta is **best effort, during business days, with no service level**: we read everything, fix what we can in the next drop, and tell you when we cannot. Findings feed directly into GA certification.

## 7. Licensing during the beta {#licensing}

Every **SQL Server Database (Beta)** target needs a beta licence key in its **License Key** property (`ip_mssql_database_license`). The plug-in checks the key on the agent host every 15 minutes — and again as soon as the property changes — and reports the result in the target's **License** metric:

| Status | Meaning | What to do |
|---|---|---|
| `Active` | The key is genuine, issued for this plug-in, and in date | Nothing |
| `License Required` | No key has been entered | Enter your beta key in the License Key property |
| `Invalid Signature` | The key text was altered | Paste the key exactly as issued, as one line |
| `Wrong Product` | The key was issued for a different plug-in (for example a GA key on the beta) | Use the key issued for `ip.em.xmsb` |
| `Expired` | The key's expiry date has passed | Request a new key |
| `Exceeded Limit` | More licensed targets exist than the key's instance count | Request an increased instance count, or remove a target |

For a key that carries an instance limit, checking the count means asking the OMS how many targets of this type exist; if that check itself cannot complete (for example a transient OMS outage), the metric reports `Instance Count Unavailable` rather than either passing or failing the target on a guess. A key with no instance limit never needs this check.

**While the status is anything but `Active`, the plug-in raises a CRITICAL incident on the `License` metric** — every other metric group keeps collecting normally. This release does not stop collection when a licence is missing or invalid; the incident on the `License` metric, and the `days_remaining` threshold in [Alerts and thresholds](alerts-and-thresholds.md#thresholds), are the signal. Enter a valid key and the status clears at its next check.

---

*Open Beta build. Not for production monitoring or compliance-of-record. See section 2.*
