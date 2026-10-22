---
title: Targets and properties
nav_order: 6
---

# Targets and properties

Before the plug-in can monitor anything, you add each Db2 database as an IBM Db2 Database target (`ip_db2_database`) in Enterprise Manager and give it a licence key. You can also add each Db2 instance as an IBM Db2 Instance target (`ip_db2_instance`). This page is for the Enterprise Manager administrator who adds and maintains those targets. It covers every target property, how to add a target from the console and with EM CLI, licensing, instance targets, the associations Enterprise Manager derives, and the connection settings for Db2U and IBM Db2 SaaS.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS and to the agent that will monitor the target: see [Deploy to the OMS](install-and-upgrade.md#deploy-oms) and [Deploy to agents](install-and-upgrade.md#deploy-agents).
> - A Db2 login for [the monitoring role](prerequisites.md#monitoring-role).
> - A licence key for `ip.em.xdb2`: see [Trial setup](trial.md).

**Where to find it:** **Setup → Add Target → Add Targets Manually**. To change a target you already added, open it and go to **Target Setup → Monitoring Configuration**. Databases on an agent host can also be [discovered automatically](discovery.md).

**In this page:** Database target properties · IPv6 hosts · Add a target from the console · Add a target with EM CLI · Modifying a target · Licensing · Instance targets · Associations · Db2U and IBM Db2 SaaS

## Database target properties {#target-properties}

| Property (console label) | Required | Default | Notes |
| :--- | :---: | :--- | :--- |
| Database Name | Yes | | The Db2 database (alias) to monitor. |
| Host | No | `localhost` | Db2 server host name, IPv4 address or IPv6 address. See [IPv6 hosts](#ipv6). |
| Port | No | `50000` | Db2 listener port (TLS instances use their `ssl_svcename` port). |
| User | No (credential) | | Monitoring user, for example `oem_monitor`. |
| Password | No (credential) | | Monitoring user password (hidden). |
| Use SSL/TLS? | No | `no` | Enables TLS transport. |
| Client Truststore Location | No (credential) | | Path to the truststore holding the server certificate. |
| Client Truststore Type | No (credential) | | Truststore format, for example `JKS` or `PKCS12`. |
| Client Truststore Password | No (credential) | | Truststore password (hidden). |
| DRDA Credential Encryption AES-256 | No | `no` | How the agent authenticates: `no`, user ID and password; `yes`, the same encrypted on the DRDA stream (not the data); `kerberos`, a Kerberos ticket ([Kerberos](prerequisites.md#kerberos)). Labelled *DRDA Data-Stream Encryption* before this release. |
| Query Timeout (seconds) | No | `60` | Cancels any single collection query that runs longer, so a blocked query cannot hold the collector. Raise it for a very large or busy database. |
| HADR Alternate Servers | No | | Client reroute: where to connect when this server cannot serve, for example after an HADR takeover. See [HADR monitoring](hadr-monitoring.md#client-reroute). |
| HADR Alternate Ports | No | | The ports of those servers, in the same order. |
| Client Affinities List | No | `no` | `YES` tries this server, then the alternates, in a fixed order. |
| Client Reroute Retries | No | `2` | How many times to retry the list, 1 second apart. |
| Affinity Failback Interval (seconds) | No | driver default | With client affinities, how often to try going back to the first server. |
| TLS Hostname Validation | No | `BASIC` | With TLS on, `OFF` skips the check that the server certificate names this host, keeping the truststore check. See [Optional transport security](prerequisites.md#tls). |
| Plug-in Licence Key | Yes, to collect (credential) | | Your Integration Plumbers licence key, in the *IBM DB2 Plug-in Licence Monitoring Credentials* set (hidden). See [Licensing](#licensing). |
| Plugin Licence Key (legacy - set the credential instead) | No | | Where the key lived before this release. Still read while the credential is empty; move the key and clear this. See [Moving a key you entered before this release](#moving-a-key). |
| OMS Host / OMS Port (licence instance count) | Limited-instance keys only | | Where the licence instance count reaches the OMS. See [The OMS settings](#oms-settings). |
| OMS API Communication | No | `STRICT` | How the licence instance count connects to the OMS. See [The OMS settings](#oms-settings). |

Credentials (the user and password, the truststore fields and the licence key) are stored obfuscated in the agent's `targets.xml`, passed to the collector on its standard input, and never logged. The Host, Port and Database Name properties are checked before use: a value outside the rules fails collection with an error that names the property, not the value.

## IPv6 hosts {#ipv6}

A Db2 server reached over IPv6 is monitored like any other: put its address in **Host**.

- **Bare or bracketed.** `2001:db8::10` and `[2001:db8::10]` are the same host. Every standard text form is accepted, including an IPv4-mapped address. A value that is not a well-formed address, or that has anything after the closing bracket, fails collection with an error naming the Host property.
- **Zone ids.** A link-local address (`fe80::...`) needs the agent host's network interface after `%`: its name on Linux (`fe80::10%eth0`), its index on Windows (`fe80::10%12`), written as is, not as `%25`. Prefer a global or unique-local address when the server has one.
- **The Db2 server must accept IPv6 connections.** The instance needs TCP/IP enabled (`DB2COMM=TCPIP`) and its port listening on an IPv6 address: on the Db2 host, `ss -ltn` (Linux) or `netstat -an` should show the port on `[::]` or `*`, not only on `0.0.0.0`.
- **Local features.** The agent counts Db2 as on its own host (the `local` property, which gates diagnostic-log monitoring and the local jobs) when the Host resolves to an address of the agent hostname, IPv4 and IPv6 alike; `localhost`, `127.0.0.1` and `::1` are always local. An address that is configured on the agent host but is not its hostname's, such as a floating HADR virtual IP, counts as remote. A host name that resolves to several addresses counts as local when **any** of them is the agent's, so do not give a target a name with records for both HADR nodes: use each node's own name or address.
- **HADR alternate servers** have not been verified with IPv6 addresses; use host names there.

## Add a target from the console {#add-target-console}

1. Go to **Setup → Add Target → Add Targets Manually**.
2. Choose **Add Target Declaratively** (add a single target manually).
3. Select target type **IBM Db2 Database** and the **Monitoring Agent** that will run the collection.
4. Fill in the properties from the table above: at minimum, **Database Name** and the **User** and **Password** monitoring credentials. Set **Host** and **Port** if the database is not on the agent host or not on `50000`.
5. To enable TLS, set **Use SSL/TLS?** to `yes` and supply the truststore fields; or set **DRDA Credential Encryption AES-256** to `yes` to encrypt the credentials only. See [Optional transport security](prerequisites.md#tls).
6. Enter your key in **Plug-in Licence Key**.
7. Click **Test Connection**, then save.

## Add a target with EM CLI {#add-target-emcli}

```
emcli add_target \
  -name="<target_display_name>" \
  -type="ip_db2_database" \
  -host="<agent_host>" \
  -properties="ip_db2_database_dbname:<DBNAME>;ip_db2_database_host:<db_host>;ip_db2_database_port:50000"
```

Each property is `name:value`, separated by `;`. The licence key is not a property any more: set it through its credential set, below.

`add_target` may print `Cannot save the target to the agent ... Null userid is not supported`. That is expected at this point: the target is created, but it has no credentials yet. The next command completes it.

Add the monitoring credentials through the monitoring credential set:

```
emcli set_monitoring_credential \
  -target_name="<target_display_name>" \
  -target_type="ip_db2_database" \
  -set_name="DB2DatabaseMonitoringCreds" \
  -cred_type="DB2DatabaseCreds" \
  -attributes="DB2Username:<user>;DB2Password:PWTAG" \
  -input_file="PWTAG:<file holding only the password>"
```

Then the licence key, through its own set:

```
emcli set_monitoring_credential \
  -target_name="<target_display_name>" \
  -target_type="ip_db2_database" \
  -set_name="DB2LicenseMonitoringCreds" \
  -cred_type="DB2LicenseCreds" \
  -attributes="DB2LicenseKey:LICTAG" \
  -input_file="LICTAG:<file holding only the licence key>"
```

`-input_file` substitutes the tag with the file's contents, so the password and the key are never on the command line or in shell history. Delete the files afterwards.

**Always add the monitoring credentials through the monitoring credential set** (`emcli set_monitoring_credential`, or the console's Monitoring Configuration page after the target exists), never as inline `-properties` or `-credentials` on `add_target`. Passed inline, the user name and password are stored as ordinary target properties, readable by anyone with access to the target, including an AI client through the [Enterprise Manager MCP Server](mcp-server.md), rather than only by Enterprise Manager's credential store. To check a target, list its properties with `emcli list -resource=TargetProperties -search="TARGET_NAME='<name>'" -columns=PROPERTY_NAME`, and re-add the credentials through the credential set if `DB2Username` or `DB2Password` is listed.

For TLS, add the `ip_db2_database_use_secure:yes` property and, for private certificates, the truststore credential set `DB2TruststoreMonitoringCreds` (location, type, password). For DRDA encryption, add `ip_db2_database_drda_encrypt:yes`.

## Modifying a target {#modify-target}

Edit an existing target under **Target → Target Setup → Monitoring Configuration**. You can change the host, port or database, rotate the monitoring credentials, renew the licence key, or turn TLS or DRDA encryption on or off there. Use **Test Connection** to confirm the change before saving.

From EM CLI, change a property with `emcli modify_target ... -on_agent`. Without `-on_agent` the change reaches only the repository, and with it the change can take one more collection cycle to reach the agent.

## Licensing {#licensing}

The plug-in is licensed per target. Every IBM Db2 Database target needs a licence key from Integration Plumbers. **Until a target has a valid, unexpired key, it collects almost nothing.**

### Entering the key {#entering-the-key}

The key is a credential: it goes into the target's **IBM DB2 Plug-in Licence Monitoring Credentials** set (`DB2LicenseMonitoringCreds`, credential type `DB2LicenseCreds`, one field, **Plug-in Licence Key**). Enterprise Manager keeps it in its credential store and hands it to the collector on its standard input. It is not a target property, so users with view access to the target, and the MCP server's `ListTargetProperties`, cannot read it.

- **Console:** **Target → Target Setup → Monitoring Configuration**, field **Plug-in Licence Key**.
- **EM CLI:** put the key alone in a file, then run the `DB2LicenseMonitoringCreds` command under [Add a target with EM CLI](#add-target-emcli). **Renewing** a key is the same command with the new key.

Paste the key exactly as issued. It is one line of `name=value` pairs separated by `|`, ending in a signature. Changing any character, including a space in the customer name, invalidates the signature. The key is for this plug-in (`ip.em.xdb2`) only: a key issued for the Open Beta plug-in, `ip.em.xdbb`, is rejected as `Invalid Signature`, and the reverse is also true.

**Removing** the key from the credential set: EM CLI cannot empty this set (`clear_monitoring_credential` and `clear_credential` do not clear it, and an empty `-input_file` is an EM CLI error). Run the command with a file holding a single space instead. The plug-in treats a blank key as not set, so the target falls back to the legacy property, or reads `License Required` if that is empty too.

### Moving a key you entered before this release {#moving-a-key}

Before 24.1.2.0.0 / 13.5.3.0.0 the key was the plain property **Plugin Licence Key** (`ip_db2_database_license`). After the upgrade it is still read, but only while the credential is empty, so an upgraded target keeps collecting with nothing re-entered. While it stays there, the key is readable as a target property. To hide it, for each target:

1. Set the key in the credential set, as above. From the next collection the credential is the one used; the property is ignored.
2. Clear the old property:

   ```
   emcli modify_target -name="<target_display_name>" -type="ip_db2_database" \
     -properties="ip_db2_database_license:" -on_agent
   ```

   or empty **Plugin Licence Key (legacy - set the credential instead)** on the Monitoring Configuration page.
3. Check that the **License** group still reads `Active` after its next collection (every 15 minutes, plus one cycle for a `modify_target -on_agent` change), and that `emcli list -resource=TargetProperties -search="TARGET_NAME='<name>'"` no longer shows the key. The property row itself stays, with an empty value. A target that reads `License Required` has neither: repeat step 1.

Do not do step 2 before step 1. Do not re-enter a renewed key in the old property: the credential always wins, so a key renewed there does nothing while the credential holds the old one.

### Licence statuses {#licence-statuses}

The **License** metric group, collected every 15 minutes, reports the customer, licence type, expiration, licensed instance count, days remaining, and the licence status:

| Status | Meaning | Collection |
| :--- | :--- | :--- |
| `Active` | Valid, unexpired key | Runs normally |
| `License Required` | No key is set on the target | **Stopped** |
| `Invalid Signature` | The key was altered, truncated, or issued for another plug-in | **Stopped** |
| `Grace Period` | The key expired less than 14 days ago | Runs; the status alert is a **Warning** |
| `Expired` | The key expired 14 or more days ago | **Stopped** |
| `Exceeded Limit` | More IBM Db2 Database targets than the key allows (see [Instance counting](#instance-counting)) | Runs, and the status alert stays open |

Two alerts ship enabled on this group: on **Licence Severity** (`license_severity`), a **Warning** during the grace period and **Critical** for any other status that is not `Active`; and **Warning at 30 days / Critical at 7 days** before the key expires. A key with expiration `Never` has no expiry alert. On an OMS upgraded from GA, `license_severity` fills only after the OMS restart the upgrade needs ([Upgrade notes](upgrade-notes.md#restart-oms)).

When the status is `License Required`, `Invalid Signature` or `Expired`, every metric group **except** `Response` (availability), `License`, `Version`, `CollectorStatus` and `readiness_summary` stops collecting. Each stopped group shows a metric collection error beginning `Collection stopped by license status`, and CollectorStatus reports it as `DISABLED`. Availability keeps working, so a missing key never makes a database look down. Collection resumes on the next cycle after a valid key is set, with no restart.

**What the signature protects.** The licence key is a commercial entitlement record, not copy protection. Its signature detects accidental or casual edits, such as a changed instance count or expiry date; it does not resist someone who extracts the signing material from the shipped plug-in.

### Instance counting {#instance-counting}

A key carries a licensed instance count, or `Unlimited`. Only this plug-in's own IBM Db2 Database targets count toward it, each once; IBM Db2 Instance targets, beta targets and other vendors' Db2 targets do not.

- **`Unlimited`:** the plug-in does not count targets and never contacts the OMS.
- **Any instance count:** the License group counts the IBM Db2 Database targets through the OMS REST API and reports `Exceeded Limit` when there are more than the key allows. The count is cached on the agent for 24 hours, so adding or removing targets shows up within a day. GA did not count keys of 100 instances or more; they are counted now, so a target with such a key needs the OMS settings below.

If the OMS cannot be reached when the count is due, a count taken in the last 7 days is used instead, and the plug-in log says so, so a short OMS outage or restart does not turn the License group into a collection error. Configuration problems are never covered this way, and are reported at the next collection: a missing OMS setting, a credential the OMS rejects, an OMS certificate the agent does not trust, or an OMS host name that does not resolve. An expired key reads `Expired` and does not contact the OMS.

### The OMS settings (limited keys only) {#oms-settings}

The count needs to reach the OMS. Set these on each target that carries a key with an instance count:

| Setting | Where | Value |
| :--- | :--- | :--- |
| **OMS Host (licence instance count)** | Property `ip_db2_database_oms_host` | The OMS host name |
| **OMS Port (licence instance count)** | Property `ip_db2_database_oms_port` | The OMS console HTTPS port |
| **IBM DB2 OMS Monitoring Credentials** | Monitoring credential set `DB2OmsMonitoringCreds` (credential type `DB2OmsCreds`) | An Enterprise Manager user that can **view** the IBM Db2 Database targets. Nothing more is needed |

Set the credential through the credential set, never inline:

```
emcli set_monitoring_credential -target_name="<target_display_name>" -target_type="ip_db2_database" \
  -set_name="DB2OmsMonitoringCreds" -cred_type="DB2OmsCreds" \
  -attributes="DB2OmsUsername:<em user>;DB2OmsPassword:PWTAG" \
  -input_file="PWTAG:<file holding only the password>"
```

The connection is HTTPS with certificate and host-name validation on. If your OMS still presents its default self-signed certificate, the preferred fix is to import that certificate into the agent's Java truststore. Otherwise set the target's **OMS API Communication** property (`ip_db2_database_license_verification_mode`):

| Value | Effect |
| :--- | :--- |
| `STRICT` (also blank) | Default: HTTPS, verifies the OMS certificate and host name |
| `SECURE` | HTTPS with no certificate check. Despite the name, weaker than `STRICT`: use it only where the OMS certificate cannot be imported |
| `INSECURE` | No certificate check, and an HTTP fallback that sends the OMS password Base64-encoded. Lab use only |

It replaces the two GA properties *OMS: skip certificate validation* and *OMS: allow cleartext HTTP fallback*: after the upgrade, set it on any target that used them.

**Which truststore.** The collector runs on the JVM that `JAVA_HOME` names in the agent's `emd.properties` (`<agent instance>/sysman/config/emd.properties`). That is not always the agent home's own JDK: for the central agent on the OMS host, it is the OMS home's JDK. As the agent owner:

```
J=<the JAVA_HOME from emd.properties>
$J/bin/keytool -printcert -sslserver <oms host>:<oms console port> -rfc > oms_chain.pem
csplit -s -z -f oms_cert- oms_chain.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
for f in oms_cert-*; do
  $J/bin/keytool -importcert -noprompt -trustcacerts -alias "em-oms-$f" -file "$f" \
    -keystore $J/jre/lib/security/cacerts -storepass <truststore password, default changeit>
done
```

On a JDK 9 or later the file is `$J/lib/security/cacerts`. Import into every agent that monitors a target with a limited key. An agent patch that replaces the JDK replaces the truststore, so check again after patching. The next License collection should read `Active`. If the count still cannot reach the OMS, the License group shows a metric collection error naming the cause; the other groups keep collecting, because the collection gate never depends on the count. See [Troubleshooting](troubleshooting.md#oms-licence-count).

### Renewing or replacing a key {#renewing}

A new key (a renewal, a larger instance count, or a replacement) takes effect at the next collection after it is set, with no restart. Set it before the old one expires: an expired key keeps collecting for 14 days (`Grace Period`), then stops.

1. Set the new key in the licence credential set on every target that carries the old one. A target still on the legacy property: put the new key in the credential set, then clear the property ([Moving a key](#moving-a-key)).
2. If the new key has an instance count and the old one was `Unlimited`, set [the OMS settings](#oms-settings) on those targets first.
3. Within 15 minutes, the **License** group on each target reads `Active` with the new expiration and instance count. The License Info page shows the same.
4. The old key needs no revoking: once no target carries it, it is not used.

## Instance targets (IBM Db2 Instance) {#instance-targets}

A Db2 **instance** (the database manager, for example `db2inst1`) runs one or more databases. Memory, agents, the database manager configuration (DBM CFG), the registry, the product level and the diagnostic log belong to the instance, not to any one database. An **IBM Db2 Instance** target (`ip_db2_instance`), new in 24.1.2.0.0 / 13.5.3.0.0, monitors those once per instance, so you can see the instance as a whole, alert on it once, and start or stop it from one place. The database targets do not change: they keep every metric, threshold and page they had, the instance-scope groups included.

### What it collects

| Group | What it shows | Interval |
| :--- | :--- | :--- |
| `Response` | Is the instance answering: Status 1 (up) or 0 (down), and a Detail in words, for example "Up: instance db2inst1 is ACTIVE." | 5 min |
| `Instance_Status` | Instance status, start time, uptime, service level, local databases and connections, per member. Warns when the instance is quiescing or quiesced | 5 min |
| `Agent_Connection`, `FCM_Buffers`, `Latch_Waits` | As on the database target, with the same thresholds | 15 to 30 min |
| `Instance_Memory` | Instance memory used, limit and peak per member, and utilisation (Warning 90%, Critical 97%) | 15 min |
| `Memory_Sets` | Every memory set of the instance and of each active database | 30 min |
| `Active_Databases` | The databases active on the instance now, with their memory | 15 min |
| `Diag_Log_File_Monitoring` | The instance's `db2diag.log`, with the same patterns as the database target. Agents on the Db2 server only (`local` = 1) | 30 min |
| `License`, `CollectorStatus` | As on the database target | 15 / 5 min |
| Configuration (daily) | DBM CFG, registry, instance and product, system, and the DBM CFG security settings, in the configuration snapshot `Db2InstanceConfiguration` | 24 h |

**How "up" is decided.** The instance is up when it accepts the connection and reports `ACTIVE`. It is also up when the connection database refuses at database level, because only a running instance can say "this database is an HADR standby", "quiesced", "not found" or "in a pending state"; the other groups then record `DISABLED` in CollectorStatus with that reason, and raise no false alerts. A wrong password, a missing privilege or a TLS problem is a metric collection error, never Down. A connection that cannot reach the instance, an instance that is not started, or any failure the plug-in does not recognise is Down, so an unknown failure still pages.

Its six console pages (Overview, Memory, Diagnostics, Configuration, Monitoring Readiness and License Info) are on [Monitoring pages](monitoring-pages.md#52-ibm-db2-instance-pages).

### Properties

| Property (console label) | Required | Notes |
| :--- | :---: | :--- |
| Host (the Db2 server) | Yes | Host name or address of the Db2 server, as on a database target (IPv6 included) |
| Port (SVCENAME, or SSL_SVCENAME with TLS) | Yes | The instance's `SVCENAME` port, or its `SSL_SVCENAME` port with TLS |
| Connection Database (any database on this instance) | Yes | The database the agent connects through to read the instance. See below |
| Instance Name (optional; checked against the instance reached) | No | For example `db2inst1`. When set, a host and port that lead to a different instance give a collection error naming both, instead of monitoring the wrong instance |
| Plug-in Licence Key | Yes, to collect (credential) | The licence credential set `DB2InstanceLicenseMonitoringCreds`. See [Licensing for instance targets](#instance-licensing) |
| Use SSL/TLS?, DRDA Credential Encryption AES-256, Query Timeout, TLS Hostname Validation | No | The same meaning as on a database target |
| User, Password | Credential | The monitoring credential set below |
| Client Truststore Location / Type / Password | Credential | The truststore credential set below |

There are no HADR alternate server properties (an instance does not fail over as a unit) and no OMS properties.

**Choosing the connection database.** The instance target reads everything through one database. Instance data is the same whichever database you choose, so pick one that is **always active** and **never an HADR standby**. A standby without reads on standby refuses every connection, so the instance still reads up but every other group is `DISABLED` until a takeover. A database that is deactivated, quiesced or dropped has the same effect; if you drop or rename it, change the property.

### Credentials

| Credential set (console name) | Credential type | What for |
| :--- | :--- | :--- |
| `DB2InstanceMonitoringCreds` (IBM Db2 Instance Monitoring Credentials) | `DB2InstanceCreds` (user, password) | Monitoring. The same monitoring user as the databases works: `CONNECT` on the connection database plus `SQLADM`. No extra grant is needed |
| `DB2InstanceTruststoreMonitoringCreds` | `DB2InstanceTruststoreCreds` (location, type, password) | TLS with a private CA, as on a database target |
| `DB2InstanceLicenseMonitoringCreds` (IBM Db2 Instance Plug-in Licence Monitoring Credentials) | `DB2InstanceLicenseCreds` | The licence key |
| `DB2HostCreds` (IBM Db2 Instance Host Credentials) | `DB2HostCreds` | Preferred credentials for the start and stop jobs: the instance owner OS account |
| `DB2AgentOwnerCreds` | `DB2HostCreds` | Preferred credentials for the diagnostics and cache-purge jobs: the agent install owner |

The credential types are the instance target's own: a database target's named credentials of type `DB2DatabaseCreds` cannot be used for an instance target. Create a named credential of type `DB2InstanceCreds` with the same user and password.

### Adding an instance target

**Console:** **Setup → Add Target → Add Targets Manually → Add Target Declaratively**, target type **IBM Db2 Instance**. Choose the agent on the Db2 server itself where you can, so that the diagnostic-log group and the start and stop jobs work there.

**EM CLI,** in steps as for a database target:

```
emcli add_target -name="db2inst1 on db2prod01" -type="ip_db2_instance" -host="<agent_host>" \
  -properties="ip_db2_instance_host:db2prod01.example.com;ip_db2_instance_port:50000;ip_db2_instance_dbname:SALES"

emcli set_monitoring_credential -target_name="db2inst1 on db2prod01" -target_type="ip_db2_instance" \
  -set_name="DB2InstanceMonitoringCreds" -cred_type="DB2InstanceCreds" \
  -attributes="DB2Username:<user>;DB2Password:PWTAG" \
  -input_file="PWTAG:<file holding only the password>"

emcli set_monitoring_credential -target_name="db2inst1 on db2prod01" -target_type="ip_db2_instance" \
  -set_name="DB2InstanceLicenseMonitoringCreds" -cred_type="DB2InstanceLicenseCreds" \
  -attributes="DB2LicenseKey:LICTAG" -input_file="LICTAG:<file holding only the licence key>"
```

Keep colons out of instance target names: EM CLI job property files write a target as `<name>:<type>`.

### Licensing for instance targets {#instance-licensing}

An IBM Db2 Instance target **does not count** against the licensed instance count, but it **does need a key** to collect. Use the same key as the instance's databases, in its own licence credential set. It checks the key on the agent only and never contacts the OMS, so it has no OMS settings, even with a limited key.

Without a valid key it behaves as a database target does: `Response`, `License`, `Version` and `CollectorStatus` keep collecting, and everything else stops with "Collection stopped by license status". Its License group has the same columns, statuses and alerts as the database target's; `Exceeded Limit` never appears on it. Before instance metadata 1.3 the key was the property `ip_db2_instance_license`: move it as for a database target ([Moving a key](#moving-a-key)).

### Known limits

- **IP address against host name.** A database registered by IP address and an instance registered by host name (or the reverse) are not associated. Register both the same way.
- **Service names as ports.** When the instance's `SVCENAME` is a service name, such as `db2c_db2inst2`, rather than a number, the collected value matches no port. The instance target's own Port property still matches, so set it to the number the service name stands for.

### Duplicate alerts: an instance breach alerts on the instance and on every database {#duplicate-alerts}

The instance-scope groups (`Instance_Memory`, `Agent_Connection`, `FCM_Buffers`, `Latch_Waits`, `Memory_Sets` and `Diag_Log_File_Monitoring`) are collected on **both** target types. One breach therefore opens an incident on the instance target **and** on each of its database targets: with five databases, one `Instance_Memory` breach opens six incidents. Nothing changes until you add an instance target.

**Workaround:** once an instance has its own target, remove the thresholds of those groups from its **database** targets and keep them on the instance target. Use a monitoring template that names those columns with no Warning and no Critical value, and apply it to the database targets of instances that have an instance target. Applied with the default `-replace_metrics=0`, it clears only the columns it names. For a single target, **Monitoring → Metric and Collection Settings** on the database target does the same. The database pages keep their data; only the duplicate alerts stop. Check the result with `emcli get_threshold` on one database target. See [Monitoring templates](alerts-and-templates.md#monitoring-templates).

## Associations {#associations}

Enterprise Manager links each Db2 target to related targets, which places it in topology views and in the **Related Targets** region on the Overview page.

| Association | From | To | How Enterprise Manager decides |
| :--- | :--- | :--- | :--- |
| `monitored_by` | The database | Its agent | Set for every agent-monitored target. |
| `hosted_by` | The database | The agent's host | Set by Enterprise Manager. On a remotely monitored database it is the agent's host, **not** the database server. |
| `runs_on` | The database | The host target it runs on | The server name the database reports is matched to a host target of the same name, exactly or by short name. No match means no `runs_on`, for example on a Windows server that reports its NetBIOS name. |
| `depends_on` | A target with HADR Alternate Servers and Ports set (normally the HADR primary) | Each Db2 target those alternates name | Each host:port is matched to a Db2 target with the same database name, port and host. See [HADR monitoring](hadr-monitoring.md#associations). |
| `runs_on` | The database | The IBM Db2 Instance target it lives in | Host and port: the database's Host matches the instance's Host (exactly or by short name), and its Port equals the instance's Port, or its collected `SVCENAME` or `SSL_SVCENAME`. `localhost` means the agent's host. At most one instance per database. |
| `runs_on` | An IBM Db2 Instance target | The host target it runs on | As for the database: the server name the instance reports. |

All of these are derived from the configuration collection (daily), and the instance link also when the Host or Port of either target changes. A change to the alternates, or a target added after the last collection, appears at the next configuration collection; to see it sooner, run the configuration collection. If two instance targets match one database, the database is linked to the first by target name: remove the duplicate.

## Db2U and IBM Db2 SaaS (not certified) {#db2u-saas}

**Neither platform has been tested with the plug-in.** This section is written from IBM's documentation; monitoring may work, but it is not certified. On both platforms the agent cannot run where Db2 runs, so the target is always **remotely monitored**: the JDBC metrics are expected to work, and diagnostic-log monitoring (CollectorStatus reports it `DISABLED`), the local administrative jobs, and Kill on the Locks and Sessions pages are unavailable.

### Db2U (Db2 on Red Hat OpenShift and Kubernetes)

| Property | What to set |
| :--- | :--- |
| Host | Never a pod IP address, which changes whenever the pod is rescheduled. Use the host name of a cluster node (or a load balancer in front of the nodes) for the **NodePort** service the operator creates (`c-<deployment>-db2u-engn-svc`), or the host name of a **LoadBalancer** service. Do not use `localhost` (for example through `oc port-forward`): the plug-in would then treat the database as local |
| Port | For the NodePort, the **node port** of the `ssl-server` port (TLS) or the `legacy-server` port, a number in the cluster's node-port range (default 30000 to 32767), not 50001. For a LoadBalancer, `50001` (TLS). Find the node port with `oc get svc -n <project> <service> -o jsonpath='{.spec.ports[?(@.name=="ssl-server")].nodePort}'`, and check it again after a redeploy that re-creates the service |
| Database Name | The name in the Db2 custom resource; IBM's examples use `BLUDB` |
| Use SSL/TLS? / Client Truststore | `yes`, with a truststore holding the CA. Unless you supplied your own certificate, the operator stores it in the secret `c-<deployment>-db2ssl` (`oc extract secret/c-<deployment>-db2ssl`). Import its `ca.crt` with `keytool -importcert … -storetype PKCS12` |
| TLS Hostname Validation | Keep `BASIC` if the certificate names the host you connect to. If the target reports a host-name mismatch, set it to `OFF`: the trust check stays |

- **Create the monitoring user as an ordinary user, never an administrator.** With the bundled LDAP: `oc rsh <ldap pod> /opt/ibm/ldap_scripts/addLdapUser.py -u oem_monitor -r user`. Grant the same `CONNECT` and `SQLADM`; the `GRANT SQLADM` must come from a user holding SECADM or ACCESSCTRL.
- A partitioned (MPP) Db2 Warehouse deployment is a DPF database: collected as any DPF database is, but not certified on Db2U.
- The remote admin jobs are not blocked, but not verified on Db2U. The backup directory is on the engine pod, so use a persistent volume; over TLS they use the target's client truststore.

### IBM Db2 SaaS and IBM Db2 Warehouse SaaS

Take every value from the instance's **Service credentials** in the IBM Cloud console, or from **Administration → Connections** in the Db2 web console.

| Property | What to set |
| :--- | :--- |
| Host | The host name in the credentials. Not an IP address: the addresses behind the name can change |
| Port | **Exactly the port in the credentials.** Do not assume 50001 or 50000 |
| Database Name | Usually `BLUDB` |
| Use SSL/TLS? | `yes` |
| Client Truststore | A truststore holding the service certificate, downloaded from **Administration → Connections** or decoded from `certificate_base64` in the service credentials. For Db2 Warehouse SaaS, IBM recommends a custom truststore holding both the DigiCert G1 and G5 roots |
| User / Password | A database user and password. IAM API keys and tokens are not supported |

- If the instance uses an IP allowlist, add the agent host's outbound address; with private endpoints only, the agent must reach the private endpoint.
- **IAM controls the console, not the database.** Create a dedicated, non-administrator monitoring user in the web console, then grant `CONNECT` and `SQLADM` as an administrator. Whether a customer administrator can grant `SQLADM` on SaaS is not verified; if the grant is refused, most groups fail with `SQL0551N`, shown as a Response metric error and as `COLLECTION_ERROR` rows in CollectorStatus, not as a Down target.
- **On Db2 Warehouse SaaS,** grant `SELECT` on `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE` explicitly, or the audit-posture rules have no data.
- **Do not use Online Backup:** IBM runs the backups, and there is no server directory to write to. Force Application needs authorities SaaS does not offer customers; RUNSTATS may work. Multi-partition Warehouse plans are DPF databases, not certified on SaaS. IBM manages HADR on SaaS plans, and what the HADR groups show there is not verified.

> **Warning: a stale password locks the SaaS monitoring account.** Db2 SaaS locks a user after repeated failed logins (at least 3), and its password policies can expire passwords. The plug-in opens a new connection for each collection, so a target left on an old password **locks its own account within the first collection cycle**, and keeps it locked (`ERRORCODE=-4214, SQLSTATE=28000`). Give the monitoring user a policy whose expiry you control, and rotate in one step: black out the target, change the password in Db2 SaaS, update the target's monitoring credential, run **Test Connection**, end the blackout. If the account is already locked, fix the credential in Enterprise Manager first, then unlock it; otherwise the next collection locks it again.

## Related

- [Prerequisites](prerequisites.md): supported versions, the monitoring role, and network requirements before you add a target
- [Target discovery](discovery.md): let each agent host propose its local databases as targets
- [Install and upgrade](install-and-upgrade.md): deploy the plug-in to the OMS and to agents before adding targets
- [HADR monitoring](hadr-monitoring.md): the client-reroute properties, and adding a standby as a target
- [Monitoring pages](monitoring-pages.md): what the targets show once they are collecting
- [Troubleshooting](troubleshooting.md#licence-gate): what an unlicensed or misconfigured target looks like
