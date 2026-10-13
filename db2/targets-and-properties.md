---
title: Targets and properties
nav_order: 6
---

# Targets and properties

Before the plug-in can monitor anything, you add each Db2 database as an `ip_db2_database` target — shown in the console as **IBM DB2 Database** — in Enterprise Manager, and give it a licence key. This page covers every target property, how to add a target both from the console and from the command line with EM CLI, and how licensing works.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS and to the agent host that will monitor the target — see [Deploy to the OMS](install-and-upgrade.md#deploy-oms) and [Deploy to agents](install-and-upgrade.md#deploy-agents).
> - A Db2 login for [the monitoring role](prerequisites.md#monitoring-role).
> - A licence key for `ip.em.xdb2` — see [Trial setup](trial.md).

**Where to find it:** Setup ▸ Add Target ▸ Add Targets Manually. To change properties on a target you already added, open the target and go to Target Setup ▸ Monitoring Configuration.

**In this page:** Add a target from the console · Instance properties and credentials · Add a target with EM CLI · Modifying a target · Licensing

## Add a target from the console {#add-target-console}

1. Go to **Setup → Add Target → Add Targets Manually**.
2. Choose **Add Target Declaratively** (add a single target manually).
3. Select target type **IBM DB2 Database** and the **Monitoring Agent** that will run the collection.
4. Fill in the instance properties from the table below — at minimum, **Database Name**, and the **User**/**Password** monitoring credentials; set **Host** and **Port** if the database is not on the agent host or not on `50000`.
5. To enable TLS, set **Use SSL/TLS?** to `yes` and supply the truststore fields; or set **DRDA Data-Stream Encryption** to `yes` for DRDA-level encryption instead. See [Optional transport security](prerequisites.md#tls).
6. Enter your **Plugin Licence Key**.
7. Click **Test Connection**, then save.

## Instance properties and credentials {#target-properties}

| Target Property | Required | Default | Notes |
| :--- | :---: | :--- | :--- |
| Database Name | Yes | — | The Db2 database (alias) to monitor. |
| Host | No | `localhost` | Db2 server hostname. |
| Port | No | `50000` | Db2 listener port (TLS instances use their `ssl_svcename` port). |
| User | No (credential) | — | Monitoring user, for example `oem_monitor`. |
| Password | No (credential) | — | Monitoring user password (hidden). |
| Plugin Licence Key | Yes, to collect | — | Your Integration Plumbers licence key. Without a key in `Active` status, every metric group except Response, License, Version and CollectorStatus stops collecting — see [Licensing](#licensing). |
| Use SSL/TLS? | No | `no` | Enables TLS transport. |
| Client Truststore Location | No (credential) | — | Path to the truststore holding the server certificate. |
| Client Truststore Type | No (credential) | — | Truststore format, for example `JKS` or `PKCS12`. |
| Client Truststore Password | No (credential) | — | Truststore password (hidden). |
| TLS Hostname Validation | No | `BASIC` | With TLS on, `OFF` skips the check that the server certificate names this host, keeping the truststore check. See [Optional transport security](prerequisites.md#tls). |
| DRDA Data-Stream Encryption | No | `no` | Encrypts userid and password on the DRDA stream (256-bit AES). |
| Query Timeout (seconds) | No | `60` | Cancels any single collection query that runs longer, so a blocked query cannot hold the collector. Raise it for a very large or busy database. |
| HADR Alternate Servers | No | — | Client reroute: where to connect when this server cannot serve, for example after an HADR takeover. See [HADR monitoring](hadr-monitoring.md#client-reroute). |
| HADR Alternate Ports | No | — | The ports of those servers, in the same order. |
| Client Affinities List | No | `no` | `YES` tries this server, then the alternates, in a fixed order. |
| Client Reroute Retries | No | `2` | How many times to retry the list, 1 second apart. |
| Affinity Failback Interval (seconds) | No | driver default | With client affinities, how often to try going back to the first server. |
| OMS Host / OMS Port (licence instance count) | Limited-instance keys only | — | Where the licence instance count reaches the OMS. See [The OMS settings](#oms-settings). |
| OMS: skip certificate validation (insecure, lab only) | No | `false` | Stops validating the OMS certificate and hostname on the licence instance-count connection only. See [Troubleshooting](troubleshooting.md#oms-licence-count). |
| OMS: allow cleartext HTTP fallback (insecure, lab only) | No | `false` | Permits retrying the licence instance-count call over plain HTTP when HTTPS fails. See [Troubleshooting](troubleshooting.md#oms-licence-count). |

Credentials — the User/Password and truststore fields — are stored obfuscated in the agent's `targets.xml`, passed to the collector over STDIN, and never logged.

## Add a target with EM CLI {#add-target-emcli}

```
emcli add_target \
  -name="<target_display_name>" \
  -type="ip_db2_database" \
  -host="<agent_host>" \
  -properties="ip_db2_database_dbname:<DBNAME>;ip_db2_database_host:<db_host>;ip_db2_database_port:50000;ip_db2_database_license:<licence key>"
```

Each property is `name:value`, separated by `;`. Do not add a `-subseparator` option: the licence key itself contains `=`.

`add_target` may print `Cannot save the target to the agent ... Null userid is not supported`. That is expected at this point: the target is created, but it has no credentials yet. The next command completes it.

Add the monitoring credentials afterwards, through the monitoring credential set:

```
emcli set_monitoring_credential \
  -target_name="<target_display_name>" \
  -target_type="ip_db2_database" \
  -set_name="DB2DatabaseMonitoringCreds" \
  -cred_type="DB2DatabaseCreds" \
  -attributes="DB2Username:<user>;DB2Password:PWTAG" \
  -input_file="PWTAG:<file holding only the password>"
```

`-input_file` substitutes `PWTAG` with the file's contents, so the password is never on the command line or in shell history. Delete the file afterwards.

**Always add the monitoring credentials through the monitoring credential set** (`emcli set_monitoring_credential`, or the console's Monitoring Configuration page after the target exists), never as inline `-properties` or `-credentials` on `add_target`. Passed inline, the username and password are stored as ordinary target properties, readable by anyone with access to the target rather than only by Enterprise Manager's credential store.

For TLS, add the `ip_db2_database_use_secure:yes` property and, for private certificates, the truststore credential set `DB2TruststoreMonitoringCreds` (location, type, password). For DRDA encryption, add `ip_db2_database_drda_encrypt:yes`.

## Modifying a target {#modify-target}

Edit an existing target under **Target → Target Setup → Monitoring Configuration**. You can change host, port, or database, rotate the monitoring credentials, update the licence key, or turn TLS/DRDA encryption on or off there. Use **Test Connection** to confirm the change before saving.

## Licensing {#licensing}

The plug-in is licensed per target. Every `ip_db2_database` target needs a licence key from Integration Plumbers. **Until a target has a valid, unexpired key, it collects almost nothing.**

### Entering the key

Paste the key into the target's **Plugin Licence Key** property:

- **Console:** **Target → Target Setup → Monitoring Configuration**.
- **EM CLI:** `-properties` on `add_target` (above), or afterwards:

```
emcli modify_target -name="<target_display_name>" -type="ip_db2_database" \
  -properties="ip_db2_database_license:<licence key>" -on_agent
```

Paste the key exactly as issued. It is one line of `name=value` pairs separated by `|`, ending in a signature. Changing any character, including a space in the customer name, invalidates the signature. The key is for this plug-in (`ip.em.xdb2`) only: a key issued for the Open Beta plug-in, `ip.em.xdbb`, is rejected as `Invalid Signature`, and the reverse is also true.

### Licence statuses {#licence-statuses}

The **License** metric group, collected every 15 minutes and again as soon as the key changes, reports the customer, licence type, expiration, licensed instance count, days remaining, and the licence status:

| Status | Meaning | Collection |
| :--- | :--- | :--- |
| `Active` | Valid, unexpired key | Runs normally |
| `License Required` | No key is set on the target | **Stopped** |
| `Invalid Signature` | The key was altered, truncated, or issued for another plug-in | **Stopped** |
| `Expired` | Past the key's expiration date | **Stopped** |
| `Exceeded Limit` | More `ip_db2_database` targets than the key allows (see instance counting below) | Runs, and the status alert stays open |

Two alerts ship enabled on this group: **Critical** whenever the status is anything other than `Active`, and **Warning at 30 days / Critical at 7 days** before the key expires. A key with expiration `Never` has no expiry alert.

When the status is `License Required`, `Invalid Signature` or `Expired`, every metric group **except** Response (availability), License, Version and CollectorStatus stops collecting. Each stopped group shows a metric collection error beginning `Collection stopped by license status`, and CollectorStatus reports it as `DISABLED`. Availability keeps working, so a missing key never makes a database look down. Collection resumes on the next cycle after a valid key is entered.

### Instance counting

A key carries a licensed instance count, or `Unlimited`. Only this plug-in's own targets (`ip_db2_database`) count toward it — beta targets and other vendors' Db2 targets do not.

- **`Unlimited`, or 100 instances or more:** the plug-in does not count targets and never contacts the OMS.
- **Fewer than 100 instances:** the License group counts the `ip_db2_database` targets through the OMS REST API and reports `Exceeded Limit` when there are more than the key allows. The count is cached on the agent for 24 hours, so adding or removing targets shows up within a day.

### The OMS settings (limited keys only) {#oms-settings}

The count needs to reach the OMS. Set these on each target that carries a limited key:

| Setting | Where | Value |
| :--- | :--- | :--- |
| **OMS Host (licence instance count)** | instance property `ip_db2_database_oms_host` | The OMS host name |
| **OMS Port (licence instance count)** | instance property `ip_db2_database_oms_port` | The OMS console HTTPS port |
| **IBM DB2 OMS Monitoring Credentials** | monitoring credential set `DB2OmsMonitoringCreds` (credential type `DB2OmsCreds`) | An Enterprise Manager user that can **view** the `ip_db2_database` targets. Nothing more is needed |

Set the credential the same way as the database credential, through the credential set and never inline:

```
emcli set_monitoring_credential -target_name="<target_display_name>" -target_type="ip_db2_database" \
  -set_name="DB2OmsMonitoringCreds" -cred_type="DB2OmsCreds" \
  -attributes="DB2OmsUsername:<em user>;DB2OmsPassword:PWTAG" \
  -input_file="PWTAG:<file holding only the password>"
```

The connection is HTTPS with certificate and host-name validation on. If your OMS still presents its default self-signed certificate, import that certificate into the agent's Java truststore — see [Troubleshooting](troubleshooting.md#oms-licence-count). If the count cannot reach the OMS, the License group shows a metric collection error naming the cause (a missing OMS Host, OMS Port or OMS credential is named as such); the other groups keep collecting, because the collection gate never depends on the count.

## Related

- [Prerequisites](prerequisites.md) — supported versions, the monitoring role, and network requirements before you add a target.
- [Install and upgrade](install-and-upgrade.md) — deploy the plug-in to the OMS and to agents before adding targets.
- [HADR monitoring](hadr-monitoring.md) — the client-reroute properties, and adding a standby as a target.
- [Monitoring pages](monitoring-pages.md) — what the target shows once it is collecting.
- [Troubleshooting](troubleshooting.md#licence-gate) — what an unlicensed or misconfigured target looks like.
