---
title: Prerequisites
nav_order: 4
---

# Prerequisites

This page lists what has to be in place before you deploy the IBM Db2 plug-in and add a target, for the Enterprise Manager administrator and the Db2 DBA who share that set-up. It falls into four groups: Enterprise Manager and an agent that can reach the database; a network path over Db2's listener port; a least-privilege monitoring user; and, only for the local administrative jobs and diagnostic-log monitoring, an agent on the Db2 host. The remote administrative jobs need a separate Db2 admin user instead. TLS, DRDA encryption and Kerberos are optional and configured on the client side. Three optional agent settings close the page: sizing, the collection throttle and batch collection.

**Where to find it:** every item below is a one-time set-up step outside the plug-in. Once a target exists, its [Monitoring Readiness](monitoring-pages.md#monitoring-readiness) page checks the connection, the licence, the monitor authority, the monitor switches, deadlock capture, HADR and the diagnostic log, and prints the statement that fixes each gap.

**In this page:** Supported versions and platforms · Enterprise Manager and agents · The JDBC driver · Network and ports · The monitoring role · Optional transport security · Kerberos authentication · Preferred Credentials for jobs · Sizing · Pausing collection when the agent host is busy · Batch collection · Prerequisites checklist

## Supported versions and platforms {#supported-versions}

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | 13.5 and 24ai |
| IBM Db2 LUW | **12.1** (certified at the Comprehensive level) and **11.5** (certified at the Basic level). Every metric collects on both; the level is the certification label in Enterprise Manager's plug-in catalog |
| Db2 LUW 11.1 and below | Not supported |
| Single-partition databases | Supported, on Db2 LUW Enterprise Server or any single-member edition |
| Partitioned (DPF) databases | **Supported.** Every member is read and the figures are aggregated. The HADR groups and diagnostic-log monitoring stay single-partition only. See [Partitioned (DPF) databases](metrics-reference.md#dpf) |
| pureScale | **Member and cluster caching facility (CF) health only: implemented, not lab-certified.** Every other metric group stays off on pureScale. See [pureScale](metrics-reference.md#purescale) |
| Db2 for z/OS | Not supported |
| Agent platforms | Linux x86-64 (64-bit), Microsoft Windows x86-64 (64-bit). AIX, Solaris, HP-UX and other agent platforms are not supported: the plug-in does not deploy to them |
| Amazon RDS for Db2 | **Not certified.** Monitoring works over JDBC, and the local-only features are unavailable. The monitoring user needs two extra grants (below). See [Troubleshooting](troubleshooting.md#rds-for-db2) |
| Db2 on Red Hat OpenShift or Kubernetes (Db2U), IBM Db2 SaaS and IBM Db2 Warehouse SaaS | **Not certified.** Monitoring may work, and the local-only features are unavailable. See [Db2U and IBM Db2 SaaS](targets-and-properties.md#db2u-saas) |

The plug-in is built and tested against single-member databases, and against a partitioned (DPF) database with two logical partitions on one host. pureScale health is written from IBM's documentation and has not run on a pureScale cluster.

**What happens on an unsupported version, and on each topology.** The plug-in detects both when a target is added (the `dbMetaVersion` and `dbTopology` target properties; `dbTopology` is `SINGLE`, `DPF` or `PURESCALE`):

- **Availability (Response) is still monitored** on any Db2 version and topology, so the target is never left without an up/down status.
- **On an unsupported Db2 version every other metric group is gated off, and says why.** The target's **CollectorStatus** metric reports each one as `DISABLED` with the reason, for example "Unsupported Db2 version 11.1…".
- **On DPF** every group collects, plus `Member_Status`, except `HADR_Status`, `HADR_Readiness` and `Diag_Log_File_Monitoring`, which CollectorStatus reports as `DISABLED` with the reason.
- **On pureScale** only `Member_Status`, `PureScale_Members`, `PureScale_CFs` and `PureScale_GBP` collect; every other group is `DISABLED` with the reason. The plug-in never collects one member and presents it as the whole database.
- **If the topology cannot be read**, the database is treated as single-partition, so a detection problem never stops a supported database from being monitored.

**After an in-place Db2 upgrade** (for example 11.5 to 12.1), the detected version refreshes when the agent restarts or the plug-in is redeployed. To refresh it straight away, run `emctl reload agent dynamicproperties <target name>:ip_db2_database` on the agent host.

## Enterprise Manager and agents {#enterprise-manager}

This release ships as two plug-in builds with the same features: **24.1.2.0.0** for Enterprise Manager 24ai and **13.5.3.0.0** for Enterprise Manager 13.5. Enterprise Manager refuses the build it was not compiled for at import (`Incompatible version`), so use the archive that matches your OMS.

| Requirement | Detail |
| :--- | :--- |
| OMS / repository | Enterprise Manager 13.5 or 24ai, up and running |
| Management Agent | An Enterprise Manager Management Agent on a host that can reach the Db2 server, on Linux x86-64 or Windows x86-64 |
| Agent JRE | The agent's Java runtime (`JAVA_HOME`) runs the plug-in's collector; no separate JDK install is required |

Before you add any target, import the plug-in archive, deploy it to the OMS, then deploy it to each agent that will monitor a Db2 database. See [Install and upgrade](install-and-upgrade.md#import).

Every target needs a licence key for `ip.em.xdb2`, held in its licence credential set. See [Licensing](targets-and-properties.md#licensing).

## The JDBC driver {#jdbc-driver}

**No separate driver installation is required.** The IBM Data Server Driver for JDBC and SQLJ (type-4, `db2jcc4.jar`, jcc `12.1.4.0`) ships bundled inside the plug-in's collector JAR, and connects to both supported Db2 versions.

**You do not need to supply a driver or a licence JAR.** The bundled type-4 driver connects to Db2 11.5 and 12.1 on Linux, UNIX and Windows without one. IBM's `db2jcc_license_cisuz.jar` is for Db2 Connect to Db2 for z/OS and IBM i, which this plug-in does not support.

The plug-in still reads one directory on each agent, for support-directed use such as a diagnostic driver build. It **survives plug-in upgrades**:

```
<agentStateDir>/ip_plugin/xdb2/lib/
```

`agentStateDir` is an agent property (see `emd.properties`); on a typical Linux agent it is the agent instance directory. The directory belongs to this plug-in alone.

- It is **created automatically** the first time a collection runs.
- **Only IBM Db2 driver JARs are loaded from it**: files named `db2jcc*.jar`. Anything else in the directory is ignored.
- JAR files placed in it are picked up at the next collection; **no plug-in redeploy is needed**.
- It is **optional**. With the directory absent or empty, the plug-in uses its bundled driver, which is the default configuration.
- The bundled driver is placed on the classpath **before** anything in this directory, so a JAR here cannot silently replace the driver the plug-in was tested against.
- To confirm a JAR was picked up, set `IP_PLUGIN_DEBUG=true` in the agent's environment and restart the agent: the collector then writes the directory it read, the JARs it matched and skipped, and the full classpath to the agent log.

## Network and ports {#network}

The agent needs a TCP path to the Db2 server on the Db2 listener port, `50000` by default (a TLS-enabled instance normally uses a separate `ssl_svcename` port). Open that path from every agent host to every database it will monitor. A server reached over IPv6 works the same way; see [IPv6 hosts](targets-and-properties.md#ipv6).

**Local-only features.** Diagnostic-log monitoring and the plug-in's six local administrative jobs (start instance, stop instance, quiesce, unquiesce, archive the active log, and kill application) require the agent to be **on the same host as the Db2 instance**. The plug-in enforces this: each of those jobs refuses to run unless the agent is on the Db2 host. Metric collection works over the network regardless, and so do the three remote administrative jobs and Explain, which need only the target's JDBC connection. Amazon RDS for Db2, Db2U and IBM Db2 SaaS are always monitored remotely, so the local-only features are unavailable there. See [Jobs](jobs-and-metric-extensions.md).

## The monitoring role {#monitoring-role}

The plug-in connects over JDBC as a dedicated, low-privilege monitoring user, never `SYSADM`, `DBADM` or `DATAACCESS`. Db2 LUW authenticates externally (OS or LDAP), so create the OS user first (example: `oem_monitor`), then grant it database authorities:

```sql
-- Connect as an instance/DB administrator to the monitored database:
--   db2 connect to <DBNAME>

-- 1. Allow the user to connect to the database.
GRANT CONNECT ON DATABASE TO USER oem_monitor;

-- 2. SQLADM carries EXECUTE on the MON_GET_* monitoring table functions
--    (and EXPLAIN / RUNSTATS) without broad data access.
GRANT SQLADM ON DATABASE TO USER oem_monitor;
```

`SQLADM` is the single grant that covers the whole metric surface: it executes every `MON_GET_*` table function the plug-in uses. The plug-in uses no discontinued `SNAP_GET_*` interfaces. The same user, with the same two grants, monitors an IBM Db2 Instance target.

**Both halves of that are measured, not asserted**, against a live Db2 12.1.4 instance:

- **`SQLADM` is required.** With it revoked, leaving `CONNECT` alone, 21 of 24 collection categories fail with `SQLCODE=-551 SQLSTATE=42501`. There is nothing in the grant set to trim.
- **The user is kept out of table data.** `SELECT COUNT(*)` on an ordinary user table is refused with `SQL0551N`. The monitoring account can see how the database is behaving and cannot read a row of what is in it.

### RESTRICTIVE databases, including Amazon RDS for Db2 {#restrictive}

The JDBC driver runs its SQL through the packages in the `NULLID` schema. A normal database grants EXECUTE on them to `PUBLIC`. A database created `RESTRICTIVE` does not, and there the monitoring user logs in and then fails **every** query with `SQLCODE=-551, SQLSTATE=42501` naming a `NULLID` package. Check with `SELECT VALUE FROM SYSIBMADM.DBCFG WHERE NAME = 'restrict_access'`. If it is `YES`:

- **On Amazon RDS for Db2** (every RDS database is RESTRICTIVE), grant AWS's role and the one package it lacks:

  ```sql
  GRANT ROLE ROLE_NULLID_PACKAGES TO USER oem_monitor;
  GRANT EXECUTE ON PACKAGE NULLID.ATSQ0A TO USER oem_monitor;
  ```

  On RDS, create the monitoring user with `rdsadmin.add_user`, connected to the `rdsadmin` database (it runs asynchronously), then grant `CONNECT` and `SQLADM` in the monitored database as above.

- **On a self-managed RESTRICTIVE database**, grant EXECUTE on the `NULLID` packages. Generate the statements, then run the output:

  ```sql
  SELECT 'GRANT EXECUTE ON PACKAGE NULLID."' || PKGNAME || '" TO USER oem_monitor;'
    FROM SYSCAT.PACKAGES WHERE PKGSCHEMA = 'NULLID';
  ```

Package EXECUTE lets the driver run statements. It grants no access to table data.

### More granular alternative (optional)

If policy forbids `SQLADM`, grant `EXECUTE` on each `MON_GET_*` function the plug-in calls instead. This is verbose and must be extended as metric families grow:

```sql
GRANT EXECUTE ON FUNCTION SYSPROC.MON_GET_DATABASE   TO USER oem_monitor;
GRANT EXECUTE ON FUNCTION SYSPROC.MON_GET_BUFFERPOOL TO USER oem_monitor;
-- ...one GRANT EXECUTE per MON_GET_* function used by the collections...
```

### Audit-posture and privilege catalog views

The audit-posture compliance rules read `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE`, and the privilege rules read the catalog's authority views. In a default Db2 installation these need no extra grant, because `SELECT` on the `SYSCAT` views is granted to `PUBLIC`. A hardened installation is the exception: security baselines such as the DISA STIG for Db2 LUW recommend revoking `PUBLIC` from them. Where that has been done, grant explicit read access:

```sql
GRANT SELECT ON TABLE SYSCAT.AUDITPOLICIES TO USER oem_monitor;
GRANT SELECT ON TABLE SYSCAT.AUDITUSE      TO USER oem_monitor;
```

These grants give read access to the audit **configuration** only, never to audit **records**, and never `SECADM`. If a grant is missing, only that collection fails with an authorization error; every other collection is unaffected, and the rules that read it have no data to evaluate rather than silently passing. See [Compliance standards](compliance-standards.md).

### Optional: deadlock capture and Explain

- **Deadlock capture** is opt-in. Only if a DBA sets up the locking event monitor does the monitoring user need one more grant: `SELECT` on that monitor's tables. See [Deadlocks](metrics-reference.md#deadlocks). Without it, only the Deadlocks group is affected, and it says so.
- **Explain Plan** needs the Db2 explain tables and `INSERT` and `SELECT` grants on them. See [Explain SQL Statement](jobs-and-metric-extensions.md#explain).

## Optional transport security (TLS / DRDA) {#tls}

Transport security is configured on the client (agent) side and needs no database grant.

- **TLS/SSL.** The DBA enables TLS on the instance (`ssl_svr_keydb`, stash, `ssl_svcename`). On the target, set **Use SSL/TLS?** to `yes` and, for a private or self-signed certificate, provide a **Client Truststore** (location, type, password) holding the server certificate. If **Use SSL/TLS?** is `yes` and no truststore is set, the driver validates against the agent JVM's default `cacerts`: fine for a public-CA certificate, but a private or self-signed Db2 certificate will not validate.
  - **Hostname validation.** By default the driver also checks that the server certificate names the host the target connects to, in its CN or a subject alternative name. A certificate issued for another name fails. Either connect by a host name the certificate holds, or set **TLS Hostname Validation** to `OFF`. `OFF` keeps the trust check, so the certificate must still be in the truststore, and skips only the name check.
  - **The security mechanism is explicit:** user ID and password, carried inside the TLS session when TLS is on, or encrypted user ID and password with DRDA encryption. It does not depend on the driver's default.
  - **A TLS problem is never reported as the database being down.** The target raises a metric collection error that names the problem: the certificate does not name the host; the certificate is not trusted (with no truststore set, the agent's Java `cacerts` was used); or there is no TLS protocol version or cipher in common with the server.
  - **The remote administrative jobs and Explain on a TLS target** need the truststore credential set, even when the agent JVM's `cacerts` already trusts the server. See [TLS targets](jobs-and-metric-extensions.md#tls-targets).
- **DRDA credential encryption.** As an alternative, set **DRDA Credential Encryption AES-256** to `yes` to encrypt the user ID and the password on the DRDA stream (256-bit AES). The property was labelled *DRDA Data-Stream Encryption* before this release; the setting and its values are unchanged. It needs an unrestricted JCE policy, which ships enabled on the JDKs the Enterprise Manager agent uses. It does **not** encrypt query results or other data on the connection; use TLS for that.

See [Targets and properties](targets-and-properties.md#target-properties) for both properties in context.

## Kerberos authentication (optional) {#kerberos}

The agent can authenticate to Db2 with a Kerberos ticket instead of a password sent to the server. Kerberos layers on TLS: set **Use SSL/TLS?** too to encrypt the session. It is verified on a Linux agent with a principal and password; Windows agents, keytab and ticket-cache modes were not verified.

**Turning it on.** Set the target's **DRDA Credential Encryption AES-256** property to `kerberos`. That property chooses how the agent authenticates (`no`: user ID and password; `yes`: the same, encrypted on the DRDA stream; `kerberos`: a ticket). To name the Db2 server's service principal, write `kerberos:<principal>`, for example `kerberos:db2inst1/db2host.example.com@EXAMPLE.COM`; plain `kerberos` lets the driver use the principal the server names. A principal the server advertises takes precedence, so `kerberos:<principal>` helps only with a server that names none. A principal may contain only letters, digits, `.`, `_`, `-`, `/` and `@`. A misspelt value (`kerbros`, `krb5`, `gssapi`) fails collection rather than sending the password as a plain user ID and password.

**The Db2 side (DBA).**

- A service principal for the instance in the KDC, by default `<instance owner>/<fully qualified host name>@<REALM>`, and its keys in a keytab the instance owner can read.
- **The keytab must reach the Db2 engine, not only the instance owner's shell.** `db2start` does not pass the instance owner's environment to the engine, so a `KRB5_KTNAME` exported in `sqllib/userprofile` alone is not enough (`db2start` fails with `gss_acquire_cred ... Key table file '/etc/krb5.keytab' not found`). Also run `db2set DB2ENVLIST=KRB5_KTNAME`, or put the keys in the default `/etc/krb5.keytab`, readable by the instance owner.
- A `krb5.conf` on the Db2 host naming the realm and its KDC.
- **The principal the instance advertises must carry its realm.** Some Kerberos libraries (MIT Kerberos 1.21 on Oracle Linux 9, for example) leave it empty, which Java rejects (`empty realm part not allowed`, driver code -4228). Set it in full with the `DB2_KRB5_PRINCIPAL` **environment variable**: add `export DB2_KRB5_PRINCIPAL=db2inst1/db2host.example.com@EXAMPLE.COM` to the instance owner's `sqllib/userprofile`, run `db2set DB2ENVLIST="KRB5_KTNAME DB2_KRB5_PRINCIPAL"`, then restart the instance. It is not a registry variable: `db2set DB2_KRB5_PRINCIPAL=...` is rejected with DBI1302E.
- The instance set to accept Kerberos, for example `db2 update dbm cfg using CLNT_KRB_PLUGIN IBMkrb5 SRVCON_AUTH KRB_SERVER_ENCRYPT`, then `db2stop` and `db2start`.
- **This also changes local connections.** With `SRVCON_AUTH KRB_SERVER_ENCRYPT`, the instance owner's local CLP connections without a user and password fail with SQL1093N: they need a Kerberos ticket too. So a target monitored by an agent on the Db2 host that still uses a plain password, and the local administrative jobs, fail. Before switching the server, move every client of the instance to Kerberos, or keep a password path for them (`KRB_SERVER_ENCRYPT` also accepts encrypted passwords; that combination was not verified).
- The monitoring grants are unchanged: Db2 maps the principal `oem_monitor@EXAMPLE.COM` to the authorization ID `OEM_MONITOR`.

**The agent side.** Kerberos is configured per agent, in the plug-in's agent state directory:

```
<agentStateDir>/ip_plugin/xdb2/krb5.conf
<agentStateDir>/ip_plugin/xdb2/jaas.conf    (optional)
```

- **`krb5.conf`** names the realm and its KDC. When it is absent, Java's own default applies: `/etc/krb5.conf` on Linux, `%WINDIR%\krb5.ini` on Windows. On the agent's Java 8, keep to the AES SHA-1 encryption types (`aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96` for `default_tkt_enctypes`, `default_tgs_enctypes` and `permitted_enctypes`) unless your agent's Java supports newer ones.
- **The credential**, one of:
  - **Principal and password (the default).** Put the principal and its Kerberos password in the target's monitoring credentials as **User** and **Password**. They are stored and delivered like a database password. The collector obtains a ticket on each connection and does not read or write a ticket cache. **Account lockout:** each collection requests its own ticket, so a wrong password fails Kerberos pre-authentication on every collection, which can lock the monitoring principal domain-wide on a KDC with a lockout policy (Active Directory). After changing the principal's password, update the monitoring credentials first, or black out the target.
  - **Keytab (no password stored in Enterprise Manager).** Create a keytab for the monitoring principal, readable only by the agent's OS user, and a `jaas.conf` beside `krb5.conf` with a `JaasClient` entry, then leave the credential's **Password** empty:

    ```
    JaasClient {
      com.sun.security.auth.module.Krb5LoginModule required
        useKeyTab=true keyTab="/path/to/oem_monitor.keytab"
        principal="oem_monitor@EXAMPLE.COM"
        storeKey=true doNotPrompt=true;
    };
    ```

    `jaas.conf` is used only by Kerberos targets whose credentials have **no** password. Whether Enterprise Manager saves monitoring credentials with an empty password was not verified.
  - **The agent user's ticket cache.** With no password and no `jaas.conf`, the collector uses the ticket the agent's OS user holds in its default ticket cache. Something must keep that ticket renewed. Prefer the keytab. Not supported on Windows.
- **Clocks.** The agent host, the Db2 host and the KDC must agree within 5 minutes.
- **Jobs** (including Explain Plan) do not read the agent state directory: they use the JVM's default `krb5.conf` location and never a `jaas.conf`, so the realm must be in that default file and the job's credentials must carry a password.

**When it fails**, the target shows a metric collection error, not a Down target: *Kerberos authentication failed*, followed by what to check and the driver's own reason. An unreachable KDC is reported the same way.

## Preferred Credentials for jobs {#preferred-credentials}

Monitoring needs only the monitoring user. The administrative jobs each run as a different account, held in a preferred credential set on the target. Set the ones you need under **Setup → Security → Preferred Credentials → IBM Db2 Database** before you run the job:

| Preferred credential set | Holds | Used by |
| :--- | :--- | :--- |
| **IBM DB2 Database Host Credentials** (`DB2HostCreds`) | The Db2 instance owner's OS account on the Db2 host | The six local administrative jobs, including **Kill** on the Locks and Sessions pages |
| **IBM DB2 Plug-in Agent Owner Credentials** (`DB2AgentOwnerCreds`) | The account that owns the agent installation (commonly `oracle`) | Purge Stale Plugin Cache, Collect IBM DB2 Plug-in Diagnostics, the three remote administrative jobs (including **Back Up Database**) and Explain |
| **IBM DB2 Database Admin Credentials** (`DB2AdminCreds`) | A Db2 admin user (a database credential) | The three remote administrative jobs only |

On Linux, the Db2 instance owner must also be able to read the agent's plug-in files, so add it to the agent install owner's group on the Db2 host: see [Jobs](jobs-and-metric-extensions.md#local-jobs). The authority the admin user needs is on [Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs). An IBM Db2 Instance target has its own host and agent-owner sets: see [Credentials](jobs-and-metric-extensions.md#credentials).

## Sizing {#sizing}

Each metric collection is a short-lived Java process that the agent starts: it opens one JDBC connection, runs its query, prints the result and exits. A database target runs about **180 collections an hour**, on intervals from 5 minutes to 24 hours. Measured on an Enterprise Manager 24ai agent on an 8-vCPU Linux host against Db2 12.1, with 1, 10 and 50 targets:

| Resource | Per target | 10 targets | 50 targets |
| :--- | :--- | :--- | :--- |
| Agent-host CPU (agent plus its collectors) | about 0.1 to 0.12 core | about 1 core | about 6 cores |
| Collector processes started | about 180 an hour | about 1,800 an hour | about 9,000 an hour |
| Db2 connections open at once | 0 to 1 | peak 2 | peak 8 |

- **Agent-host CPU:** plan for about **0.12 core per target**, and keep the plug-in's share of an agent host below about 60% of its cores: about 20 targets on a dedicated 4-core host. Spread larger estates across agents. Sustained saturation was not tested and is not a supported operating point.
- **Memory:** each running collection takes 70 to 130 MB for its short life. The agent ran at most 12 collections at once in every test, so allow about **1.5 GB** of headroom for collector processes on top of the agent's own heap, whatever the target count.
- **On the Db2 side:** each target makes about 3 short connections a minute as the monitoring user, each held for about a second. That adds little to `MAXAPPLS`, but it shows in any audit policy that records connect events: about 4,300 a day per target. The SQL groups read the package cache 8 times an hour per target, a cost that grows with the size of the package cache.

## Pausing collection when the agent host is busy (optional) {#collection-throttle}

The plug-in can skip a scheduled collection while the **agent host** is at or above a CPU or memory threshold that you set. The check runs before the collector's Java process starts, so a skipped collection costs a few small file reads and nothing else. **It is off by default.**

**How to turn it on.** On the agent host, as the agent install owner, create `collection-throttle.conf` in the plug-in's agent state directory. Like the `lib` directory, it survives plug-in upgrades:

```
<agentStateDir>/ip_plugin/xdb2/collection-throttle.conf
```

```
# Every IBM Db2 target on this agent
[*]
cpu_threshold = 90
mem_threshold = 95

# One target, by its Enterprise Manager target name. Overrides [*].
[DB2-PROD-01]   # production
cpu_threshold = 80
mem_threshold = off
```

- A threshold is a percentage greater than 0 and at most 100. Collection pauses while the measured value is **at or above** it. `off` turns that threshold off for that section.
- A section name must be the target's Enterprise Manager name **exactly**, including case. A `#` or `;` starts a comment.
- Anything that is not a valid percentage turns that threshold off rather than guessing, so a typo never stops collection. Changes take effect at the next collection; no agent restart is needed. Delete the file to turn the feature off.
- **Set thresholds well above the host's normal load.** The throttle is a safety valve for saturation, not a way to collect less often.

**What is measured.** On Linux, CPU is the 1-minute load average per CPU, as a percentage (it counts processes waiting on I/O too), and memory is `(MemTotal - MemAvailable) / MemTotal`. On Windows, CPU is processor busy time from the Windows performance counters, read through WMI, and memory comes from `Win32_OperatingSystem`; it needs the `Win32::OLE` module in the agent's Perl, and without it the feature does nothing. Inside a container, `/proc` shows the host's load and memory, not the container's limits. On other platforms nothing is measured and nothing pauses.

**What is never paused:** `Response` (availability), `CollectorStatus`, `License`, the version detection, the configuration collections, and every job. When anything goes wrong (a file that cannot be read, a measurement that fails), collection runs as normal.

**Where a paused collection shows.** The group uploads no rows for that interval, so charts show a gap. Its row in CollectorStatus gets a `Reason` that starts `Collection paused by the agent-load collection throttle`, followed by the threshold that was reached; a pause is not a new status word, so CollectorStatus's own alert is neither raised nor cleared by it. **A pause can clear and then re-raise alerts on the paused group**: Enterprise Manager may treat an empty upload from a keyed group as "these rows are gone". That is the main reason to set thresholds well above normal load.

## Batch collection (optional) {#batch-collection}

By default every metric collection starts its own Java process. With batch collection on, the first collection for a target starts a **collection helper**: one Java process that serves that target's later collections, one at a time, over one Db2 connection. It exits after a quiet period, and the next collection starts a new one. **It is off by default**, and not yet verified on Windows agents, so leave it off there.

**How to turn it on.** Add the line below to `collection-throttle.conf` (create the file if you do not use the throttle):

```
[*]                          # every IBM Db2 target on this agent
batch_collection = on

[DB2-PROD-01]                # or one target only; overrides [*]
batch_collection = off
```

| Key | Default | Meaning |
| :--- | :--- | :--- |
| `batch_collection` | `off` | `on` turns batch collection on for the section |
| `batch_idle_seconds` | 120 | The helper exits after this many seconds with no collection (10 to 900) |
| `batch_max_lifetime` | 1800 | And after this many seconds in any case (60 to 7200) |
| `batch_max_helpers` | 25 | Helpers running at once on this agent; beyond this, a target collects as before (1 to 500) |
| `batch_connection` | `shared` | `per_query` keeps one Db2 connection per query, as without batching |

**What it changes.** Measured over two 15-minute windows on an Enterprise Manager 24ai agent monitoring four Db2 12.1 targets (two databases, two instances): collector Java processes started fell by about 91%, Db2 connections opened by one database by about 80%, and agent-host CPU by about 0.3 core, with no rows lost. **What it costs:** one resident Java process per target, about 170 MB each, so plan memory for `batch_max_helpers` of them.

**What stays the same.** Credentials still reach the collector only on its standard input and are never written to a file; a helper serves one target with one set of credentials. The throttle is checked first. `License`, the version detection and every job always run in their own process. If a helper is busy for 20 seconds or stops, its waiting collections each run in their own process; a collection already being served when its helper stops reports `batch collection timed out` after 240 seconds. The helpers' files are under `<agentStateDir>/ip_plugin/xdb2/batch/`, readable only by the agent user; `fallback.log` there has one line for each collection that ran in its own process instead. Delete the line, or set it to `off`, to go back.

## Prerequisites checklist {#checklist}

**Minimum (metric monitoring)**

- [ ] Db2 LUW 11.5 or 12.1
- [ ] Enterprise Manager 13.5 or 24ai
- [ ] A valid licence key for `ip.em.xdb2`
- [ ] Plug-in archive imported, deployed to the OMS, deployed to the monitoring agent(s)
- [ ] Agent host on Linux x86-64 or Windows x86-64, with a network path to the database (JDBC, port 50000 by default)
- [ ] Monitoring OS user created (`oem_monitor` or similar)
- [ ] `GRANT CONNECT ON DATABASE TO USER oem_monitor;`
- [ ] `GRANT SQLADM ON DATABASE TO USER oem_monitor;`
- [ ] On a RESTRICTIVE database (every Amazon RDS for Db2 database), EXECUTE on the `NULLID` packages

**Full capability (adds to the minimum)**

- [ ] Agent on the Db2 host, for the six local-only administrative jobs and diagnostic-log monitoring
- [ ] **IBM DB2 Database Host Credentials** set under Preferred Credentials, for the local-only jobs; on Linux, the instance owner in the agent install owner's group
- [ ] **IBM DB2 Plug-in Agent Owner Credentials** set, for the housekeeping, diagnostics, remote jobs and Explain
- [ ] A Db2 admin user and **IBM DB2 Database Admin Credentials** set, for the remote administrative jobs and Back Up Database
- [ ] TLS, DRDA encryption or Kerberos configured, if your site requires it; on a TLS target, the truststore credential set
- [ ] The Db2 explain tables and their grants, for Explain Plan
- [ ] A locking event monitor and its `SELECT` grant, for Recent Deadlocks
- [ ] `SELECT` granted on `SYSCAT.AUDITPOLICIES` / `SYSCAT.AUDITUSE`, only if `PUBLIC` access to those views has been revoked

## Related

- [Install and upgrade](install-and-upgrade.md#import): import the plug-in and deploy it to the OMS and agents
- [Targets and properties](targets-and-properties.md#target-properties): add a target and set the TLS, DRDA and Kerberos properties
- [Jobs](jobs-and-metric-extensions.md): the local and remote administrative jobs and the credentials they need
- [Compliance standards](compliance-standards.md): what the audit-posture and privilege rules read
- [Monitoring pages](monitoring-pages.md#monitoring-readiness): the Monitoring Readiness page, which checks much of this list live
