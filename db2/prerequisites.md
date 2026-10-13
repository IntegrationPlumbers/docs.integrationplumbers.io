---
title: Prerequisites
nav_order: 4
---

# Prerequisites

What the plug-in needs falls into four groups: Enterprise Manager and an agent that can reach the database; a network path over Db2's listener port; a least-privilege monitoring user; and, only for the five local-only administrative jobs and diagnostic-log monitoring, an agent co-located on the Db2 host. The three remote administrative jobs need a separate Db2 admin user instead. Optional TLS or DRDA encryption is configured entirely on the client side and needs no extra database grant.

**Where to find it:** every item below is a one-time setup step outside the plug-in itself; nothing here is checked live on a console page in this release.

**In this page:** Supported versions and platforms · Enterprise Manager and agents · The JDBC driver · Network and ports · The monitoring role · Optional transport security (TLS / DRDA) · Preferred Credentials for jobs · Sizing · Prerequisites checklist

## Supported versions and platforms {#supported-versions}

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | 13.5 and 24ai |
| IBM Db2 LUW | **12.1** (certified at the Comprehensive level) and **11.5** (certified at the Basic level). Every metric collects on both; the level is the certification label in Enterprise Manager's plug-in catalog |
| Db2 LUW 11.1 and below | Not supported |
| Db2 topology | A **single-partition** database on Db2 LUW Enterprise Server, or any single-member edition |
| Partitioned (DPF) and pureScale databases | Not supported |
| Db2 for z/OS | Not supported |
| Agent platforms | Linux x86-64 (64-bit), Microsoft Windows x86-64 (64-bit) |
| Amazon RDS for Db2 | **Not certified.** Monitoring may work, but it has not been certified, and the local-only features are unavailable there — see [Troubleshooting](troubleshooting.md#rds-for-db2) |

**What happens on an unsupported version or topology.** The plug-in detects both when a target is added. Availability (**Response**) is still monitored on any Db2 version, so the target is never left without an up/down status. Every other metric group is gated off, and the target's **CollectorStatus** metric reports each one as `DISABLED` with the reason — "Unsupported Db2 version …" or "Unsupported topology …". If the topology cannot be read, the database is treated as single-partition, so a detection problem never stops a supported database from being monitored.

## Enterprise Manager and agents {#enterprise-manager}

This release ships as two plug-in builds with the same features: **24.1.1.0.0** for Enterprise Manager 24ai and **13.5.2.0.0** for Enterprise Manager 13.5. Enterprise Manager refuses the build it was not compiled for at import (`Incompatible version`), so use the artifact that matches your OMS.

| Requirement | Detail |
| :--- | :--- |
| OMS / repository | Enterprise Manager 13.5 or 24ai, up and running |
| Management Agent | An Enterprise Manager Management Agent on a host that can reach the Db2 server, on Linux x86-64 or Windows x86-64 |
| Agent JRE | The agent's Java runtime (`JAVA_HOME`) runs the plug-in's collector; no separate JDK install is required |

Before you add any target, import the plug-in OPAR, deploy it to the OMS, then deploy it to each agent that will monitor a Db2 database. See [Install and upgrade](install-and-upgrade.md#import).

A valid licence key for `ip.em.xdb2` is required to monitor a target; it is a target property. See [Licensing](targets-and-properties.md#licensing).

## The JDBC driver {#jdbc-driver}

**No separate driver installation is required.** The IBM Data Server Driver for JDBC and SQLJ (type-4, `db2jcc4.jar`, jcc `12.1.4.0`) ships bundled inside the plug-in's collector JAR, and connects to both certified Db2 versions.

**You do not need to supply a driver or a licence JAR.** The bundled type-4 driver connects to Db2 11.5 and 12.1 on Linux, UNIX and Windows without one. IBM's `db2jcc_license_cisuz.jar` is for Db2 Connect to Db2 for z/OS and IBM i, which this plug-in does not support.

The plug-in still reads one directory on each agent, for support-directed use such as a diagnostic driver build. It **survives plug-in upgrades**:

```
<agentStateDir>/ip_plugin/xdb2/lib/
```

`agentStateDir` is an agent property (see `emd.properties`); on a typical Linux agent it is the agent instance directory. The directory belongs to this plug-in alone.

- It is **created automatically** the first time a collection runs.
- **Only IBM Db2 driver JARs are loaded from it** — files named `db2jcc*.jar`. Anything else in the directory is ignored.
- JAR files placed in it are picked up at the next collection; **no plug-in redeploy is needed**.
- It is **optional**. With the directory absent or empty, the plug-in uses its bundled driver, which is the default configuration.
- The bundled driver is placed on the classpath **before** anything in this directory, so a JAR here cannot silently replace the driver the plug-in was tested against.

## Network and ports {#network}

The agent needs a TCP path to the Db2 server on the Db2 listener port, `50000` by default (a TLS-enabled instance normally uses a separate `ssl_svcename` port). Open that path from every agent host to every database it will monitor.

**Local-only features.** Diagnostic-log monitoring and the plug-in's five local administrative jobs — start instance, stop instance, quiesce, unquiesce, and kill application — require the agent to be **co-located on the same host as the Db2 instance**. The plug-in enforces this: each of those jobs refuses to run unless the agent is on the Db2 host. Remote monitoring of metrics works over the network regardless, and so do the three remote administrative jobs, which need only the target's JDBC connection. The local-only features are unavailable on managed services such as Amazon RDS for Db2, where there is no host to co-locate an agent on. See [Jobs](jobs-and-metric-extensions.md) and [Troubleshooting](troubleshooting.md#rds-for-db2).

## The monitoring role {#monitoring-role}

The plug-in connects over JDBC as a dedicated, low-privilege monitoring user — never `SYSADM`, `DBADM`, or `DATAACCESS`. Db2 LUW authenticates externally (OS or LDAP), so create the OS user first (example: `oem_monitor`), then grant it database authorities:

```sql
-- Connect as an instance/DB administrator to the monitored database:
--   db2 connect to <DBNAME>

-- 1. Allow the user to connect to the database.
GRANT CONNECT ON DATABASE TO USER oem_monitor;

-- 2. SQLADM carries EXECUTE on the MON_GET_* monitoring table functions
--    (and EXPLAIN / RUNSTATS) without broad data access.
GRANT SQLADM ON DATABASE TO USER oem_monitor;
```

`SQLADM` is the single grant that covers the whole current metric surface: it executes every `MON_GET_*` table function the plug-in uses, and it is `SELECT`-able on the `SYSIBMADM.DB_HISTORY` recovery-history view the backup-history metric reads. The plug-in uses no discontinued `SNAP_GET_*` interfaces.

**Both halves of that are measured, not asserted** — certified against a live Db2 12.1.4 instance:

- **`SQLADM` is genuinely required.** With it revoked — leaving `CONNECT` alone — **21 of 24** collection categories fail outright with `SQLCODE=-551 SQLSTATE=42501`. The grant set is minimal; there is nothing in it to trim.
- **The user really is kept out of table data.** `SELECT COUNT(*)` on an ordinary user table is refused with `SQL0551N`. The monitoring account can see how the database is behaving and cannot read a single row of what is in it — worth saying to anyone who asks what this account can reach.

`SYSIBMADM.DB_HISTORY` is covered too, though by `CONNECT` rather than `SQLADM` — that view stays readable with `SQLADM` revoked. So the one grant pair covers the whole current metric surface.

### More granular alternative (optional)

If policy forbids `SQLADM`, grant `EXECUTE` on each `MON_GET_*` function the plug-in calls instead. This is verbose and must be extended as metric families grow:

```sql
GRANT EXECUTE ON FUNCTION SYSPROC.MON_GET_DATABASE   TO USER oem_monitor;
GRANT EXECUTE ON FUNCTION SYSPROC.MON_GET_BUFFERPOOL TO USER oem_monitor;
-- ...one GRANT EXECUTE per MON_GET_* function used by the collections...
```

### Audit-posture catalog views

The audit-posture compliance rules read two catalog views: `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE`. In a default Db2 installation these need no extra grant — `SELECT` on `SYSCAT` catalog views is granted to `PUBLIC`, so `oem_monitor` reads them as-is. A hardened installation is the exception: security baselines such as the DISA STIG for Db2 LUW recommend revoking `PUBLIC` from them. Where that has been done, grant explicit read access:

```sql
GRANT SELECT ON TABLE SYSCAT.AUDITPOLICIES TO USER oem_monitor;
GRANT SELECT ON TABLE SYSCAT.AUDITUSE      TO USER oem_monitor;
```

These grants give read access to the audit **configuration** only — which policies exist, what they are attached to, which categories they cover — never to audit **records**, and never `SECADM`. If the grant is missing, the audit-posture collection alone fails with an authorization error; every other collection is unaffected, and the audit-posture rules simply have no data to evaluate, rather than silently passing. See [Compliance standards](compliance-standards.md).

## Optional transport security (TLS / DRDA) {#tls}

Transport security is configured on the client (agent) side and needs no database grant.

- **TLS/SSL.** The DBA enables TLS on the instance (`ssl_svr_keydb`, stash, `ssl_svcename`). On the target, set **Use SSL/TLS?** to `yes` and, for a private or self-signed certificate, provide a **Client Truststore** (location, type, password) holding the server certificate. If **Use SSL/TLS?** is `yes` and no truststore is set, the driver validates against the agent JVM's default `cacerts` — fine for a public-CA certificate, but a private or self-signed Db2 certificate will not validate.
  - **Hostname validation.** By default the driver also checks that the server certificate names the host the target connects to, in its CN or a subject alternative name. A certificate issued for another name fails. Either connect by a host name the certificate holds, or set **TLS Hostname Validation** to `OFF`. `OFF` keeps the trust check, so the certificate must still be in the truststore, and skips only the name check.
  - **The security mechanism is explicit:** user ID and password, carried inside the TLS session when TLS is on, or encrypted user ID and password with DRDA encryption. It no longer depends on the driver's default.
  - **A TLS problem is never reported as the database being down.** The target raises a metric collection error that names the problem: the certificate does not name the host; the certificate is not trusted; or there is no TLS protocol version or cipher in common with the server.
- **DRDA data-stream encryption.** As an alternative or legacy option, set **DRDA Data-Stream Encryption** to `yes` to encrypt both the userid and the password on the DRDA stream (256-bit AES). This needs an unrestricted JCE policy, which ships enabled on the modern JDKs the Enterprise Manager agent uses. It does **not** encrypt query results or other data on the connection, despite the property's name; use TLS for that.

See [Targets and properties](targets-and-properties.md#target-properties) for both properties in context.

## Preferred Credentials for jobs {#preferred-credentials}

Monitoring needs only the monitoring user. The administrative jobs each run as a different account, held in a preferred credential set on the target. Set the ones you need under **Setup → Security → Preferred Credentials → IBM DB2 Database**, before you run the job:

| Preferred credential set | Holds | Used by |
| :--- | :--- | :--- |
| **IBM DB2 Database Host Credentials** (`DB2HostCreds`) | The Db2 instance owner's OS account on the Db2 host | The five local administrative jobs, including the Analysis page's **Kill Blocking Application** button |
| **IBM DB2 Plug-in Agent Owner Credentials** (`DB2AgentOwnerCreds`) | The account that owns the agent installation (commonly `oracle`) | Purge Stale Plugin Cache, Collect IBM DB2 Plug-in Diagnostics, and the three remote administrative jobs |
| **IBM DB2 Database Admin Credentials** (`DB2AdminCreds`) | A Db2 admin user (a database credential) | The three remote administrative jobs only |

On Linux and UNIX, the Db2 instance owner must also be able to read the agent's plug-in files, so add it to the agent install owner's group on the Db2 host — see [Jobs](jobs-and-metric-extensions.md#local-jobs). The authority the admin user needs is on [Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs). Each job's credential needs, and the messages you see when one is missing, are on [Jobs](jobs-and-metric-extensions.md#credentials).

## Sizing {#sizing}

Each metric collection is a short-lived Java process that the agent starts: it opens one JDBC connection, runs its query, prints the result and exits. A target runs about **180 collections an hour**, on intervals from 5 minutes to 24 hours. Measured on an Enterprise Manager 24ai agent on an 8-vCPU Linux host against Db2 12.1:

- **Agent-host CPU:** plan for about **0.12 core per target**, and keep the plug-in's share of an agent host below about 60% of its cores — about 20 targets on a dedicated 4-core host. Spread larger estates across agents.
- **Memory:** each running collection takes 70–130 MB for its short life. The agent ran at most 12 collections at once in every test, so allow about **1.5 GB** of headroom for collector processes on top of the agent's own heap, whatever the target count.
- **On the Db2 side:** each target makes about 3 short connections a minute as the monitoring user, each held for about a second. That adds little to `MAXAPPLS`, but it shows in any audit policy that records connect events: about 4,300 a day per target.

## Prerequisites checklist {#checklist}

**Minimum (metric monitoring)**

- [ ] Db2 LUW 11.5 or 12.1
- [ ] Enterprise Manager 13.5 or 24ai
- [ ] A valid licence key for `ip.em.xdb2`
- [ ] Plug-in OPAR imported, deployed to the OMS, deployed to the monitoring agent(s)
- [ ] Agent host on Linux x86-64 or Windows x86-64, with a network path to the database (JDBC, port 50000 by default)
- [ ] Monitoring OS user created (`oem_monitor` or similar)
- [ ] `GRANT CONNECT ON DATABASE TO USER oem_monitor;`
- [ ] `GRANT SQLADM ON DATABASE TO USER oem_monitor;`

**Full capability (adds to the minimum)**

- [ ] Agent co-located on the Db2 host, for the five local-only administrative jobs and diagnostic-log monitoring
- [ ] **IBM DB2 Database Host Credentials** set under Preferred Credentials, for the local-only jobs; on Linux/UNIX, the instance owner in the agent install owner's group
- [ ] **IBM DB2 Plug-in Agent Owner Credentials** set, for the housekeeping, diagnostics and remote jobs
- [ ] A Db2 admin user and **IBM DB2 Database Admin Credentials** set, for the remote administrative jobs
- [ ] TLS or DRDA encryption configured, if your site requires encrypted transport
- [ ] `SELECT` granted on `SYSCAT.AUDITPOLICIES` / `SYSCAT.AUDITUSE`, only if `PUBLIC` access to those views has been revoked

## Related

- [Install and upgrade](install-and-upgrade.md#import) — import the OPAR and deploy it to the OMS and agents
- [Targets and properties](targets-and-properties.md#target-properties) — add a target and set the TLS/DRDA properties
- [Jobs](jobs-and-metric-extensions.md) — the local and remote administrative jobs and the credentials they need
- [Compliance standards](compliance-standards.md) — what the audit-posture rules read, and what happens without the grant
