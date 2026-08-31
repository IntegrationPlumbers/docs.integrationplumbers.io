---
title: Credentials
nav_order: 8
---

# Credentials

The plug-in connects with a read-only monitoring login. It never needs `sysadmin`, `db_owner` or `CONTROL SERVER`, and it creates nothing on the instance.

> **Prerequisites for this page**
> - The ability to create a login on the SQL Server instance, or someone who can run the script for you.
> - Enterprise Manager access that can set monitoring credentials on a target.
>
> Credentials must be applied after the target exists. Supplying them inline when the target is created does not work, and the target comes up Down with no obvious reason why.

**In this page:** The grants · Creating the login · Applying credentials to a target · Windows Integrated Authentication · Truststore credentials · Why not sysadmin

## The grants {#grants}

| Grant | Scope | What it covers |
| :--- | :--- | :--- |
| `VIEW SERVER STATE` | Server | The dynamic management views — host, CPU, memory, availability groups, clustering, waits, sessions, queries |
| `VIEW ANY DATABASE` | Server | Listing every database on the instance |
| `VIEW ANY DEFINITION` | Server | Database file metadata; metadata only, no data read, no execute |
| `CONNECT ANY DATABASE` | Server | Reaching each database for the file-group and free-space sweep |
| `db_datareader` in `msdb` | msdb | Backup history and job history |
| `SQLAgentReaderRole` in `msdb` | msdb | SQL Server Agent job and schedule definitions |

Every one is read-only metadata visibility. None allows writing data, executing code, or altering definitions.

## Creating the login {#creating}

Create it once per instance, as a `sysadmin`, then hand the plug-in only the monitoring login. A runnable setup script is available through your support channel; the grants above are the whole of what it does.

If your policy forbids one of the server-scoped grants, the plug-in still runs — the metrics that depended on it return no rows rather than failing, and the corresponding page or column is empty. `VIEW SERVER STATE` is the one that cannot be omitted: nearly every performance surface depends on it.

## Applying credentials to a target {#applying}

Credentials are applied **after** the target is created, not inline with it:

```
emcli set_monitoring_credential -target_name="<target name>" \
  -target_type="<target type>" \
  -set_name="SQLServerDatabaseMonitoringCreds" \
  -cred_type="SQLServerDatabaseCreds" \
  -attributes="SQLServerUsername:<user>;SQLServerPassword:<password>"
```

Passing `-credentials=` to `add_target` is silently ignored, which leaves a target that exists and never collects. In the console the same thing is done from **Target Setup** → **Monitoring Configuration**.

Rotating the password later is the same command again. The target picks it up on its next collection.

## Windows Integrated Authentication {#wia}

On a Windows agent, Windows Integrated Authentication is available as an alternative to a SQL login. On Linux the plug-in uses SQL authentication. Kerberos authentication is not supported on either platform.

## Truststore credentials {#truststore}

If a target verifies the server certificate, the truststore's location, type and password are held as a second credential set on that target, separate from the login above. [TLS connections](tls.md) covers it.

Worth knowing if you redeploy the plug-in: a deploy cycle can reset a target's truststore credentials to placeholder values, at which point that target goes Down with a certificate-path error until they are re-applied. If a verifying target fails right after a plug-in upgrade, check these before anything else.

## Why not sysadmin {#why-not-sysadmin}

Because it is not needed, and monitoring credentials are stored, rotated and occasionally mislaid.

A monitoring login with the grants above can read the state of the instance and nothing else. If it leaks, the exposure is metadata. The plug-in is built so that the account it runs as day to day has no power to change anything — the jobs that *do* change things run under credentials you supply at the time you run them, not under the monitoring login.

## Related

- [Prerequisites](prerequisites.md#monitoring-login) - where the monitoring login fits in the setup
- [Targets and properties](targets-and-properties.md#credentials) - applying credentials to a target
- [TLS connections](tls.md#setup) - the truststore credential set and what it is for
- [Jobs](jobs.md#prerequisites) - why job credentials are separate from monitoring credentials
- [Troubleshooting](troubleshooting.md#target-down) - what a credential failure looks like
