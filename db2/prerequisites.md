---
title: Prerequisites
nav_order: 4
---

# Prerequisites

What the plug-in needs falls into four groups: Enterprise Manager and an agent that can reach the database; a network path over Db2's listener port; a least-privilege monitoring user; and, only for the five local-only administrative jobs and diagnostic-log monitoring, an agent co-located on the Db2 host. Optional TLS or DRDA encryption is configured entirely on the client side and needs no extra database grant.

**Where to find it:** every item below is a one-time setup step outside the plug-in itself; nothing here is checked live on a console page in this release.

**In this page:** Supported versions and platforms · Enterprise Manager and agents · The JDBC driver · Network and ports · The monitoring role · Optional transport security (TLS / DRDA) · Preferred Credentials for local-only jobs · Prerequisites checklist

## Supported versions and platforms {#supported-versions}

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | 13.5 and 24ai |
| IBM Db2 LUW | **12.1** (primary, certified) and **11.5** (supported) |
| Db2 LUW below 11.5 (9.1–10.5) | Not supported |
| Agent platforms | Linux x86-64 (64-bit), Microsoft Windows x86-64 (64-bit) |
| Amazon RDS for Db2 | Documentation-verified compatibility only — see [Troubleshooting](troubleshooting.md#rds-for-db2) |

## Enterprise Manager and agents {#enterprise-manager}

This release ships as two plug-in builds with the same features: **24.1.9.7.0** for Enterprise Manager 24ai and **13.5.9.2.0** for Enterprise Manager 13.5. Enterprise Manager refuses the build it was not compiled for at import (`Incompatible version`), so use the artifact that matches your OMS.

Before you add any target, import the plug-in OPAR, deploy it to the OMS, then deploy it to each agent that will monitor a Db2 database. See [Install and upgrade](install-and-upgrade.md#import).

A valid beta licence key is required to monitor a target; it is a target property. See [Trial setup](trial.md).

## The JDBC driver {#jdbc-driver}

**No separate driver installation is required.** The IBM Data Server Driver for JDBC and SQLJ (type-4, `db2jcc4.jar`, jcc `12.1.4.0`) ships bundled inside the plug-in's collector JAR, and connects to both certified Db2 versions.

Some sites must use a driver build obtained directly from IBM, or must supply a separate IBM licence JAR their entitlement requires. Those files cannot ship with the plug-in, so the plug-in loads them from a directory on each agent that **survives plug-in upgrades**: `<agentStateDir>/ip_plugins/lib/`. The directory is created automatically the first time a collection runs. Drop JAR files directly in it — no plug-in redeploy is needed, the next collection picks them up. It is optional: with the directory absent or empty, the plug-in uses its bundled driver. The bundled driver is placed on the classpath before anything in this directory, so a JAR here cannot silently replace the driver the plug-in was tested against. Do this on every agent that monitors a Db2 target.

## Network and ports {#network}

The agent needs a TCP path to the Db2 server on the Db2 listener port, `50000` by default (a TLS-enabled instance normally uses a separate `ssl_svcename` port). Open that path from every agent host to every database it will monitor.

**Local-only features.** Diagnostic-log monitoring and the plug-in's five administrative jobs — startup, shutdown, quiesce, unquiesce, and kill application — require the agent to be **co-located on the same host as the Db2 instance**. Remote monitoring of metrics works over the network regardless; these local-only features do not, and are unavailable on managed services such as Amazon RDS for Db2 where there is no host to co-locate an agent on. See [Jobs](jobs-and-metric-extensions.md) and [Troubleshooting](troubleshooting.md#rds-for-db2).

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
- **DRDA data-stream encryption.** As an alternative or legacy option, set **DRDA Data-Stream Encryption** to `yes` to encrypt both the userid and the password on the DRDA stream (256-bit AES). This needs an unrestricted JCE policy, which ships enabled on the modern JDKs the EM agent uses.

See [Targets and properties](targets-and-properties.md#target-properties) for both properties in context.

## Preferred Credentials for local-only jobs {#preferred-credentials}

The five local-only administrative jobs and the **Kill Application** action authenticate as an operating-system user on the Db2 host, not as the monitoring database user — effectively the Db2 instance owner. Set **Agent Host Credentials** for the target before you run one:

1. Go to **Setup, Security, Preferred Credentials**, and open the **IBM DB2 Database (Beta)** target type.
2. Under **Target Preferred Credentials**, select the target's **Agent Host Credentials** row, click **Set**, choose a named host credential for the instance-owner account, and click **Test and Save**.

Without it, a job fails with `Unable to get credentials for defaultHostCred`. This is the credential the **Purge Stale Plugin Cache** job needs too — see [Jobs](jobs-and-metric-extensions.md#purge-stale-cache) for the specific account it needs (the agent install owner, not the Db2 instance owner) and why the two are easy to confuse.

## Prerequisites checklist {#checklist}

**Minimum (metric monitoring)**

- [ ] Db2 LUW 11.5 or 12.1
- [ ] Enterprise Manager 13.5 or 24ai
- [ ] A valid beta licence key
- [ ] Plug-in OPAR imported, deployed to the OMS, deployed to the monitoring agent(s)
- [ ] Agent host on Linux x86-64 or Windows x86-64, with a network path to the database (JDBC, port 50000 by default)
- [ ] Monitoring OS user created (`oem_monitor` or similar)
- [ ] `GRANT CONNECT ON DATABASE TO USER oem_monitor;`
- [ ] `GRANT SQLADM ON DATABASE TO USER oem_monitor;`

**Full capability (adds to the minimum)**

- [ ] Agent co-located on the Db2 host, for the five local-only administrative jobs and diagnostic-log monitoring
- [ ] Agent Host Credentials set under Preferred Credentials, for the local-only jobs
- [ ] TLS or DRDA encryption configured, if your site requires encrypted transport
- [ ] `SELECT` granted on `SYSCAT.AUDITPOLICIES` / `SYSCAT.AUDITUSE`, only if `PUBLIC` access to those views has been revoked

## Related

- [Install and upgrade](install-and-upgrade.md#import) — import the OPAR and deploy it to the OMS and agents
- [Targets and properties](targets-and-properties.md#target-properties) — add a target and set the TLS/DRDA properties
- [Jobs](jobs-and-metric-extensions.md) — the local-only administrative jobs and the credential they need
- [Compliance standards](compliance-standards.md) — what the audit-posture rules read, and what happens without the grant
