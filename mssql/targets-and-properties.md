---
title: Targets and properties
nav_order: 7
---

# Targets and properties

> **Prerequisites for this page**
> - The plug-in deployed to both the OMS and the agent that will monitor the instance. See [Install and upgrade](install-and-upgrade.md).
> - The monitoring login created on the SQL Server instance. See [Credentials](credentials.md#creating).

**In this page:** Adding a target · Properties · Credentials · What to point at · Collection schedules · A new target looks sparse at first

## Adding a target {#adding}

Targets are added against the Management Agent that will monitor the instance. The agent does not have to be on the database host.

```
emcli add_target -name="<target name>" -type="<target type>" -host="<agent host>" \
  -properties="<host>;<port>;<instance>;<tls mode>;<license key>"
```

Then apply credentials to the target — see [Credentials](#credentials) below, and read that section before you run the command above, because the order matters.

## Properties {#properties}

| Property | Meaning |
| :--- | :--- |
| Host | Address of the SQL Server instance, as reachable from the agent host |
| Port | TCP port, 1433 by default |
| Instance | Instance name for a named instance; leave at the default otherwise |
| TLS mode | Whether the connection is encrypted, and whether the certificate is verified |
| License Key | The beta licence key for this target (`ip_mssql_database_license`). See the [Open Beta notice](beta-pre-release.md#licensing) for what each status means. |

For certificate verification you also supply the truststore location, type and password. [TLS connections](tls.md) covers the detail.

## Credentials {#credentials}

**Credentials are not passed inline when you add the target.** This plug-in uses a monitoring credential set, so credentials are applied to the target *after* it is created:

```
emcli set_monitoring_credential -target_name="<target name>" \
  -target_type="<target type>" \
  -set_name="SQLServerDatabaseMonitoringCreds" \
  -cred_type="SQLServerDatabaseCreds" \
  -attributes="SQLServerUsername:<user>;SQLServerPassword:<password>"
```

Passing `-credentials=` to `add_target` is **silently ignored**. The target is created and then never collects, showing as Down with nothing obvious to explain it. If a freshly added target is Down, this is the first thing to check.

You can also set the credentials in the console from the target's **Target Setup** → **Monitoring Configuration** page.

## What to point at {#what-to-point-at}

| Topology | Point the target at |
| :--- | :--- |
| Standalone instance | The instance |
| Availability group | The listener, so the target follows the primary |
| A specific replica | That replica, when you want that replica's own view |
| Failover cluster instance | The virtual network name |

One target type covers all of these. The plug-in works out the topology at run time, and metric families that do not apply to an instance return no rows rather than failing — a standalone instance simply has an empty availability-group table.

Monitoring both a listener and its replicas is legitimate and gives you both views, at the cost of an extra target per replica.

## Collection schedules {#schedules}

Different metrics collect at different rates, which is deliberate — a per-database space sweep is far more expensive than reading a counter.

| Roughly | Metrics |
| :--- | :--- |
| Every minute | Instance availability |
| Every 5 minutes | Agent state, TempDB contention |
| Every 15 minutes | Deadlock rate, availability-group readiness |
| Hourly | Backup age, licence |
| Every 24 hours | Instance configuration, per-database space, database inventory |

All of these are adjustable per target under **Monitoring** → **Metric and Collection Settings**. If you shorten the 24-hour ones, be aware the space sweep visits every online database on the instance.

## A new target looks sparse at first {#new-target}

Because configuration and space are on 24-hour schedules, a target added in the last day has not collected them yet, and any surface that depends on them will be empty until it does.

The Overview page works around the two slowest by taking a one-off live reading, so server configuration and the database list appear straight away, marked as a live read. Everything else fills in as its schedule comes round.

This is normal on a new target and is not a fault. If a surface is still empty after 24 hours, that is worth reporting.

## Related

- [Credentials](credentials.md) - setting the monitoring credentials a new target needs
- [Prerequisites](prerequisites.md#network) - connectivity the agent needs to the instance
- [TLS connections](tls.md) - the two encryption modes and which property selects them
- [High availability](high-availability.md) - what to point a target at in an AG or cluster
- [Monitoring pages](monitoring-pages.md#blank) - why a new target looks sparse on its first day
- [Troubleshooting](troubleshooting.md#target-down) - a target that will not come Up
