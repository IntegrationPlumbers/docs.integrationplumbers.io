---
title: Targets and properties
nav_order: 6
---

# Targets and properties

Before the plug-in can monitor anything, you add each Db2 database as an `ip_db2_database_beta` target in Enterprise Manager. This page covers every target property and how to add a target both from the console and from the command line with EM CLI.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS and to the agent host that will monitor the target — see [Deploy to the OMS](install-and-upgrade.md#deploy-oms) and [Deploy to agents](install-and-upgrade.md#deploy-agents).
> - A Db2 login for [the monitoring role](prerequisites.md#monitoring-role).
> - A beta licence key — see [Trial setup](trial.md).

**Where to find it:** Setup ▸ Add Target ▸ Add Targets Manually. To change properties on a target you already added, open the target and go to Target Setup ▸ Monitoring Configuration.

**In this page:** Add a target from the console · Instance properties and credentials · Add a target with EM CLI · Modifying a target

## Add a target from the console {#add-target-console}

1. Go to **Setup → Add Target → Add Targets Manually**.
2. Choose **Add Target Declaratively** (add a single target manually).
3. Select target type **IBM DB2 Database (Beta)** and the **Monitoring Agent** that will run the collection.
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
| Plugin Licence Key | Yes | — | Your beta licence key. Without a key in `Active` status, every metric group except License, Response, and Version stops collecting — see [Troubleshooting](troubleshooting.md#licence-gate). |
| Use SSL/TLS? | No | `no` | Enables TLS transport. |
| Client Truststore Location | No (credential) | — | Path to the truststore holding the server certificate. |
| Client Truststore Type | No (credential) | — | Truststore format, for example `JKS` or `PKCS12`. |
| Client Truststore Password | No (credential) | — | Truststore password (hidden). |
| DRDA Data-Stream Encryption | No | `no` | Encrypts userid and password on the DRDA stream (256-bit AES). |
| OMS: skip certificate validation (insecure, lab only) | No | `false` | Stops validating the OMS certificate and hostname on the licence instance-count connection only. See [Troubleshooting](troubleshooting.md#oms-licence-count). |
| OMS: allow cleartext HTTP fallback (insecure, lab only) | No | `false` | Permits retrying the licence instance-count call over plain HTTP when HTTPS fails. See [Troubleshooting](troubleshooting.md#oms-licence-count). |

Credentials — the User/Password and truststore fields — are stored obfuscated in the agent's `targets.xml`, passed to the collector over STDIN, and never logged.

## Add a target with EM CLI {#add-target-emcli}

```
emcli add_target \
  -name="<target_display_name>" \
  -type="ip_db2_database_beta" \
  -host="<agent_host>" \
  -properties="ip_db2_database_dbname:<DBNAME>;ip_db2_database_host:<db_host>;ip_db2_database_port:50000;ip_db2_database_license:<YOUR_LICENSE_KEY>" \
  -subseparator="properties=:"
```

Add the monitoring credentials with the credential-set options, for example:

```
  -monitor_creds="ip_db2_database_beta:DB2DatabaseMonitoringCreds:DB2Username=<user>;DB2Password=<pwd>"
```

For TLS, add the `ip_db2_database_use_secure:yes` property and, for private certificates, the truststore credential set `DB2TruststoreMonitoringCreds` (location, type, password). For DRDA encryption, add `ip_db2_database_drda_encrypt:yes`.

## Modifying a target {#modify-target}

Edit an existing target under **Target → Target Setup → Monitoring Configuration**. You can change host, port, or database, rotate the monitoring credentials, update the licence key, or turn TLS/DRDA encryption on or off there. Use **Test Connection** to confirm the change before saving.

## Related

- [Prerequisites](prerequisites.md) — supported versions, the monitoring role, and network requirements before you add a target.
- [Install and upgrade](install-and-upgrade.md) — deploy the plug-in to the OMS and to agents before adding targets.
- [Monitoring pages](monitoring-pages.md) — what the target shows once it is collecting.
- [Troubleshooting](troubleshooting.md#licence-gate) — what an unlicensed or misconfigured target looks like.
