---
title: Troubleshooting
nav_order: 25
---

# Troubleshooting

Ordered by how often each one actually happens.

**In this page:** Target is Down · Target is Up but data is missing · A metric group is empty or its collection is failing · A CRITICAL incident on the License metric · Certificate problems · Jobs fail · Import and deploy problems · What to send when you report something

## Target is Down {#target-down}

**Straight after being added.** The credentials were passed inline with `add_target`, which is silently ignored by this plug-in — it uses a monitoring credential set applied *after* creation. Re-apply them and the target comes Up on its next collection. See [Credentials](credentials.md#applying).

**After a plug-in upgrade, on a target that verifies certificates.** A deploy cycle can reset truststore credentials to placeholder values. Re-apply them. Targets not verifying certificates are unaffected. See [TLS connections](tls.md#after-upgrade).

**Intermittently.** Check the agent can still reach the instance on its port, and that the monitoring login has not expired or been locked out. A password policy that expires the monitoring login will take the target Down on the next collection with no other symptom.

**With "refusing to build the JDBC URL" in the collection error.** The Host, Port or Named Instance property breaks the rules the plug-in checks before connecting: Host must be a hostname, an IPv4 address or a bracketed IPv6 address, optionally followed by `\INSTANCE`; Port a number from 1 to 65535; an instance name only the characters SQL Server allows in one. Correct the property in the target's monitoring configuration. The error names the property without repeating the value.

**Briefly, after a failover cluster instance moved.** Expected: one or two one-minute samples while the instance comes online on the other node. Nothing to change if the target points at the virtual network name. If it stays Down, it points at a node. See [High availability](high-availability.md#fci).

## Target is Up but data is missing {#missing-data}

**Everything is thin and the target is new.** Expected for up to 24 hours. Configuration, per-database space and the database inventory collect daily. The Overview page compensates with a one-off live read for the slowest two; other surfaces fill in on schedule.

**One page is empty and the rest are fine.** Usually a grant. Metrics whose permission is missing return no rows rather than failing, so the effect is a blank page rather than an error. Check the monitoring login against [Credentials](credentials.md#grants).

**A table shows fewer rows than you expect.** Some collections are deliberately filtered — index fragmentation only covers indexes above a size worth acting on, so small indexes are absent by design.

**Two families report less on SQL Server 2016 and 2017.** TempDB contention collects, but its allocation-page and metadata-page waiter counts read zero and the advice cell is blank. Cluster nodes collects node names, but status, status description and current owner are blank. Both because the view that classifies a latched page by type arrived in 2019. Read a zero or a blank as "not classifiable on this version". Not a fault.

**Non-ASCII text shows as question marks.** Every non-ASCII character in collected text, database, login and host names, SQL text, file paths, arrives as `?`, while numbers and ASCII text are fine. The agent is running without a UTF-8 locale. Restart it from a shell where one is set; see [Prerequisites](prerequisites.md#agent-locale).

**A range page says no activity was collected, or that history starts later than your range.** The page can only sum what was stored. See [Pages that take a time range](monitoring-pages.md#timespan) for what the retention and rollup messages mean; on a newly deployed plug-in they are expected.

**The Query Store views and the plan regression alert are empty.** Query Store is off in every user database, or the plug-in has not yet seen an interval close since it was deployed: the first collection records the server's time and only intervals that close after it are stored, and Query Store closes one every 60 minutes by default. Collector Status reads `NOT_CONFIGURED` for the Query Store groups with the reason when it is the former.

## A metric group is empty or its collection is failing {#collector-status}

An empty metric group looks the same on the All Metrics page, and to an AI client reading through the MCP Server, whether the feature is not set up, the group has not run yet, there was nothing to report, or the collection is failing. The **Collector Status** metric tells them apart: one row per metric group of the target, refreshed every 5 minutes even while the target is Down, with a status word from a closed set, the reason in plain text, the rows the last run returned and when it ran. Find it under the target's **All Metrics**.

| Status | Means | What to do |
|---|---|---|
| `OK` | The last collection returned rows. A group that handles its own failure and still reports a value reads `OK` too, for example Response reporting the instance down after a failed login, so `OK` does not prove the credentials work: a broken credential shows as the target going Down. | Nothing. |
| `NOT_CONFIGURED` | The feature the group measures is not set up on this instance: Always On not enabled or no availability group, not a failover cluster instance, no mirrored database, no user database with Query Store on. Reason says which. | Nothing, unless the feature should be there. |
| `NOT_COLLECTED_YET` | The group has not completed a collection on this target, usually a target added less than one interval ago. Some groups collect once a day. | Read again after the interval. |
| `NO_DATA` | It collected and there was nothing to report, for example no locks held right now, or this replica is not the primary of its availability group. | Nothing. |
| `COLLECTION_ERROR` | The collection failed. Reason carries the error. Seen on two checks in a row, 5 minutes apart, it raises a CRITICAL incident, "Collection of the ... metric group is failing", which stays open until that group's next successful run. For a group that collects hourly or daily, one failed run raises it. | Fix the cause, usually a grant the monitoring login lacks, a permission on the instance, or reachability. [Credentials](credentials.md#grants) lists the grants. |
| `DISABLED` | Skipped by design on this target, for example the Windows registry group on a Linux-hosted instance. | Nothing. |

The last attempt time is a number, seconds since 1970 in UTC, blank for a group that has never run; the older text column beside it is always blank by design. A row named `_Vocabulary` lists the whole status set in its Reason column. Two limits: the status is what the agent observed, so it can lead the repository by one upload interval, and if the agent itself is down the statuses go stale with it, which the target's own availability says.

## A CRITICAL incident on the License metric {#license}

**Symptom.** The target is Up and every page fills, but there is an open CRITICAL incident on the `License` metric, and the Monitoring and License card on the Overview page shows a status other than `Active`.

**Cause.** Every SQL Server Database target needs a licence key in its **License Key** property (`ip_mssql_database_license`). The plug-in checks the key on the agent host every 15 minutes, and again as soon as the property changes, and reports the result in the target's `License` metric. While the status is anything but `Active` it raises the incident; every other metric group keeps collecting. The incident, and the `days_remaining` threshold in [Alerts and thresholds](alerts-and-thresholds.md#thresholds), are the signal.

**Fix.** Read the `Status` column of the `License` metric and act on it:

| Status | Meaning | What to do |
|---|---|---|
| `Active` | The key is genuine, issued for this plug-in, and in date | Nothing |
| `License Required` | No key has been entered | Enter your licence key in the License Key property |
| `Invalid Signature` | The key text was altered | Paste the key exactly as issued, as one line, no wrapping, no trailing spaces |
| `Wrong Product` | The key was issued for a different plug-in, for example an Open Beta key | Use the key issued for `ip.em.xmss`; beta keys stop working on 2026-10-31 |
| `Expired` | The key's expiry date has passed | Request a new key |
| `Exceeded Limit` | More licensed targets exist than the key's instance count | Request an increased instance count, or remove a target |

For a key that carries an instance limit, checking the count means asking the OMS how many targets of this type exist; if that check cannot complete, for example during a transient OMS outage, the metric reports `Instance Count Unavailable` rather than passing or failing the target on a guess. A key with no instance limit never needs this check. Enter a valid key and the status clears at its next check; nothing needs a restart.

## Certificate problems {#certificates}

A target set to verify the certificate goes Down with a certificate-path error. In order of likelihood: an incomplete chain in the truststore, a name mismatch between the certificate and how the target connects, truststore credentials that are wrong or absent, or an expired certificate.

Quickest diagnostic: set the target's TLS Mode to `required`. If it comes Up, the network and login are fine and the problem is certificate validation. [TLS connections](tls.md#failures) has the detail.

## Jobs fail {#jobs}

**On a target that monitors perfectly well.** Jobs use a separate credential path from monitoring. A host credential must be set as a preferred credential on the SQL Server target type, and the truststore credential set must resolve on every target — using the literal `none` where no truststore is in use. See [Jobs](jobs.md#prerequisites).

**Unresolved credential reference.** The truststore credential set is empty on that target. Populate it, with `none` values if the target does not use a truststore.

**It works from the command line but not the console.** A job submitted with credentials bound explicitly bypasses preferred credentials. The console relies on the preferred credential, so this pattern means the preferred credential was never set.

**Permission denied.** Jobs need grants beyond the monitoring login's read-only set — see the table in [Jobs](jobs.md#grants). Delete backup needs `sysadmin` by SQL Server's own design and is meant to be run with override credentials.

**Create index says "Cannot find the object", or created the index in master.** The table name was given as `schema.table` and resolved in the monitoring login's default database. Give the three-part name, `database.schema.table`, or use the dialog on the Indexes page, which builds it for you. See [Jobs](jobs.md#gotchas).

**Show plan found no plan.** The job's message says why where it can: the plan has left the plan cache and Query Store is off in that database, the database is not online, or the monitoring login cannot open it. A plan older than Query Store's retention, 30 days by default, is gone.

**A parameter was rejected with a message naming it.** The value would have added or repeated an argument the job passes to the agent. Remove the stray characters from that parameter; a comma inside a value is fine and is kept as part of the value.

## Import and deploy problems {#import-deploy}

**Incompatible version on import.** The archive was built for a different Enterprise Manager release. Use the build matching yours — see [Install and upgrade](install-and-upgrade.md#which-build).

**Entity already exists.** That version is already in the Software Library. Enterprise Manager will not import the same version twice, even if the file has changed. Ask for a build with the version incremented.

## What to send when you report something {#reporting}

Send it to **helpdesk@integrationplumbers.io**. Every email opens a ticket you can follow in the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/home), or open the ticket there directly. The more of this you include, the faster it resolves:

- Enterprise Manager release, and the plug-in version from the target's page
- SQL Server version and edition, and the host operating system
- Whether the agent is local to the database host or remote
- The exact command or console action, and the exact error text
- For a monitoring problem: which page or metric, and whether the target is Up
- For a job: whether it was submitted from the console or the command line

For a target that has been up less than a day, say so — it changes what an empty page means.

## Related

- [Credentials](credentials.md) - the cause of most targets that will not come Up
- [TLS connections](tls.md#failures) - certificate and PKIX failures in detail
- [Jobs](jobs.md#gotchas) - the job failures that have no obvious cause
- [Monitoring pages](monitoring-pages.md#blank) - a blank region that is not a fault
- [AI clients and the MCP Server](mcp-server.md) - what an assistant sees, and how it should read Collector Status
- [What's new](whats-new.md#ga) - the known limitations and boundaries of this release, so you can tell a known one from a new one
