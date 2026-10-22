---
title: Target discovery
nav_order: 6.5
---

# Target discovery

Every Linux and Windows host with an Enterprise Manager agent reports its local Db2 databases to Enterprise Manager as targets ready to promote. This page is for the administrator onboarding Db2 databases: what discovery proposes, what it runs on the host, and how to promote a discovered database. There is nothing to configure. Once the plug-in is deployed on the OMS, Enterprise Manager runs discovery on every agent host every 24 hours, and you can run it at once on chosen hosts. Automatic discovery is new in 24.1.2.0.0 / 13.5.3.0.0.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS and to the agent on the Db2 host: see [Install and upgrade](install-and-upgrade.md#deploy-agents).
> - The monitoring user and its grants, to enter when you promote a target: see [The monitoring role](prerequisites.md#monitoring-role).

**Where to find it:** **Setup → Add Target → Auto Discovery Results → Targets on Hosts**.

**In this page:** What discovery proposes · What discovery does on the host · Run discovery now · Promote a discovered target

## What discovery proposes {#what-it-proposes}

One **IBM Db2 Database** target for each local database of each instance on the host:

| Field | Value |
| :--- | :--- |
| Target name | `<agent host>:<port>/<database>`, for example `db2host.example.com:50000/SAMPLE` |
| Host | The agent's host name, so the target counts as local and diagnostic-log monitoring and the local administrative jobs work |
| Port | The instance's `SVCENAME`, resolved through the services file when it is a name. An instance whose `DB2COMM` includes `SSL` and that has no plain port to offer (`DB2COMM=SSL`, or no `SVCENAME`) gets its `SSL_SVCENAME` port and **Use SSL/TLS?** = `yes`; add the truststore when you promote it ([Optional transport security](prerequisites.md#tls)) |
| Database Name | The database alias from the instance's system database directory |

- Remote catalog entries (another server's database catalogued on this one) are never proposed.
- A database catalogued under several aliases is proposed once.
- An HADR standby database is proposed like any other database on its own instance's port; read [Monitoring a standby](hadr-monitoring.md#monitoring-a-standby) before monitoring it.
- **A database that is already a target is proposed again** under its discovered name: discovery cannot tell that an existing target with another name, or one monitored from another agent, is the same database. Promote only the databases you do not monitor yet, and ignore the rest.

Discovery proposes database targets only. Add IBM Db2 Instance targets yourself: see [Instance targets](targets-and-properties.md#instance-targets).

## What discovery does on the host {#on-the-host}

It needs no password, connects to no database and changes nothing. As the agent user, it runs read-only commands:

- **Linux:** `db2ls` and each installation's `instance/db2ilist`, plus the owners of running `db2sysc` processes (for an instance `db2ilist` does not list);
- **Windows:** `reg query` for the installed Db2 copies, and each copy's `db2ilist`;
- **then, per instance:** `db2 list db directory`, `db2 get dbm cfg`, `db2set DB2COMM` and `db2 terminate`, with `DB2INSTANCE` set to that instance.

A protocol the instance does not start is not offered: with `DB2COMM=SSL` the TLS port is proposed even when `SVCENAME` is set, and an instance without `DB2COMM` (no TCP/IP listener) is skipped and logged. On Windows, discovery reads the command line processor's output in English: an agent host whose Db2 messages are in another language finds nothing, so add those databases manually.

**The agent user must be able to read the instance.** On Linux that means read access to the instance owner's `sqllib`, which a default installation gives every user. If the agent user cannot read an instance, discovery skips it and writes the reason (the Db2 message, for example `SQL1092N`) to the agent's `emagent_perl.trc` (`<agent instance>/sysman/log/`). Nothing is proposed for that instance: add its databases manually, or give the agent user read access.

## Run discovery now {#run-now}

**Setup → Add Target → Configure Auto Discovery**, select the agent host, then **Discover Now**. Or with EM CLI:

```
emcli run_auto_discovery -host="<agent host>"
emcli get_targets -unmanaged -properties | grep ip_db2_database
```

## Promote a discovered target {#promote}

1. **Setup → Add Target → Auto Discovery Results → Targets on Hosts**.
2. Select the database, then **Promote**.
3. Enter the monitoring credentials and the licence key ([Database target properties](targets-and-properties.md#target-properties)), then save.

To promote with EM CLI, add the target under its discovered name with the discovered properties ([Add a target with EM CLI](targets-and-properties.md#add-target-emcli)), then set its monitoring credentials and licence key with `set_monitoring_credential`.

## Related

- [Targets and properties](targets-and-properties.md): every property, adding a target manually, and licensing
- [Prerequisites](prerequisites.md#network): local-only features and the agent on the Db2 host
- [HADR monitoring](hadr-monitoring.md): standbys, and following the primary through a takeover
