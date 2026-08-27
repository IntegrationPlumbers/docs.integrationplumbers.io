---
title: Prerequisites
nav_order: 5
---

# Prerequisites

Most of this is already in place if you monitor SQL Server today. There are three groups: what Enterprise Manager needs, what the SQL Server side needs, and one monitoring login with a short list of read-only grants.

**In this page:** Supported versions and platforms · Enterprise Manager and agents · Network and connectivity · The monitoring login · TLS · What you do not need · Checklist

## Supported versions and platforms {#supported-versions}

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | Cloud Control 13.5, 24ai (24.1) |
| Microsoft SQL Server | 2016, 2017, 2019, 2022, 2025 |
| Management Agent | Linux x86-64, Windows x86-64 |
| SQL Server host | Windows or Linux |

Every declared version has been collected against on a live instance. On SQL Server 2016 and 2017 two metric families return less detail than they do on 2019 and later — TempDB contention collects, but the allocation-page and metadata-page waiter counts read zero because the underlying view does not expose them on those releases. Everything else is identical across versions.

## Enterprise Manager and agents {#enterprise-manager}

You need a working Enterprise Manager environment — management server and repository — and a Management Agent that can reach the instance over TCP.

The agent does **not** have to run on the SQL Server host. Remote monitoring from a Linux agent to a SQL Server on Windows is a supported and common arrangement, and it is how much of this plug-in was certified. Local agents work equally well.

Enterprise Manager will only accept a plug-in built for its own release, so use the build that matches: the `24.1.x` artifact for 24ai, the `13.5.x` artifact for 13.5. See [Install and upgrade](install-and-upgrade.html).

## Network and connectivity {#network}

The agent host needs TCP access to the instance, by default on port 1433. Named instances on non-default ports work; you give the port when you add the target.

For an availability group, point the target at the listener rather than a replica if you want the target to follow the primary.

## The monitoring login {#monitoring-login}

The plug-in connects as a read-only monitoring login. It never needs `sysadmin`, `db_owner` or `CONTROL SERVER`.

| Grant | Scope | What it covers |
| :--- | :--- | :--- |
| `VIEW SERVER STATE` | Server | The dynamic management views: host, CPU, memory, availability groups, clustering, waits, sessions |
| `VIEW ANY DATABASE` | Server | Listing every database on the instance |
| `VIEW ANY DEFINITION` | Server | Database file metadata; metadata only, no read of data, no execute |
| `CONNECT ANY DATABASE` | Server | Reaching each database for the file-group and free-space sweep |
| `db_datareader` in `msdb` | msdb | Backup and job history |
| `SQLAgentReaderRole` in `msdb` | msdb | SQL Server Agent job and schedule definitions |

Every grant is read-only metadata visibility. None confers the ability to write data, execute code, or alter definitions.

Create the login once per instance as a `sysadmin`, then give the plug-in only that login. A runnable setup script is available through your support channel.

## TLS {#tls}

The plug-in connects with encryption by default. Two modes are available and the difference matters:

- **Encrypted** — the connection is encrypted, but the server's certificate is not validated. Works with a self-signed certificate and needs nothing on the agent.
- **Encrypted and verified** — the certificate is validated against a truststore you supply. This is the stronger setting and needs the certificate chain in a truststore the agent can read.

Choose per target when you add it. [TLS connections](tls.html) covers both, including what to do when validation fails.

## What you do not need {#not-needed}

- **A JDBC driver install.** The Microsoft JDBC driver ships inside the plug-in's collection JAR. There is nothing to download, place on the agent, or keep in step with a database upgrade.
- **`xp_cmdshell`.** The plug-in's backup and restore jobs use native T-SQL. It never asks you to enable it — and it flags instances where it is enabled as a compliance finding.
- **An agent on the database host**, unless you want one.
- **A separate plug-in per SQL Server version.** One plug-in and one target type cover 2016 through 2025.

## Checklist {#checklist}

- [ ] Enterprise Manager 13.5 or 24ai, with a reachable Management Agent
- [ ] The plug-in build that matches your Enterprise Manager release
- [ ] TCP access from the agent host to the instance, default port 1433
- [ ] A monitoring login on each instance with the grants above
- [ ] For certificate validation, the chain in a truststore the agent can read
- [ ] The instance's port and, for a named instance, its instance name

## Related

- [Install and upgrade](install-and-upgrade.html) - the next step once the checklist passes
- [Credentials](credentials.html) - creating the monitoring login and granting it
- [TLS connections](tls.html) - if the instance requires encrypted connections
- [Targets and properties](targets-and-properties.html) - adding the first target
- [Getting started](getting-started.html) - the whole path, start to finish
