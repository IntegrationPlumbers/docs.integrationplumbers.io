---
title: Jobs
nav_order: 22
---

# Jobs

The plug-in ships eleven Enterprise Manager job types, so the things you find on a monitoring page can be acted on from the same console — with Enterprise Manager's own scheduling, credentials and audit trail.

> **Prerequisites for this page**
> - Job credentials set on the target. These are separate from monitoring credentials: a target that is Up and collecting tells you nothing about whether its jobs will run. See [Before jobs will run](#prerequisites).
> - The truststore credential set resolved on every target, including targets with no truststore, where it takes the literal value `none`.
> - Grants beyond the monitoring login for most jobs. See [Grants each job needs](#grants).

**In this page:** The jobs · Before jobs will run · Grants each job needs · Things that catch people out · Backups use native T-SQL

## The jobs {#the-jobs}

| Job | Does | Submitted from |
| :--- | :--- | :--- |
| Back up database | A native T-SQL backup | Databases page, or Job Library |
| Schedule backup | The same backup job on an Enterprise Manager schedule, once or daily | Databases page |
| Restore database | Restores, leaving the database ready for further backups to be applied | Databases page, or Job Library |
| Restore full database | Restores and brings the database online, over a live database if need be | Job Library |
| Delete backup | Removes a backup history entry | Databases page, or Job Library |
| Create index | Creates an index, typically one the Indexes page has suggested | Indexes page, or Job Library |
| Show query plan | Writes one execution plan's XML to the job output, by Query Store plan id or by plan hash | Query History page, or Job Library |
| Kill session | Ends a session | Job Library |
| AlwaysOn failover | Fails an availability group over | Job Library |
| Start instance, Stop instance | Starts or stops the SQL Server service | Job Library |
| Pause / resume instance | Pauses or resumes it | Job Library |

They are ordinary Enterprise Manager jobs. They can be scheduled, they appear in Job Activity, and they are audited like any other. A failed job reports Failed with the error in the step output; a job never reports Succeeded on a failure, with one known exception for a backup that fails after it has started, listed under the boundaries in [What's new](whats-new.md#ga).

**Schedule backup** is the Back Up Database job with a schedule attached, not a scheduler of the plug-in's own. The start time you pick is your own local time; a daily schedule then repeats at that time of day in the Enterprise Manager repository's time zone, for ten years or until you stop it. The scheduled job sits in Enterprise, Job, Activity, where it can be edited or stopped like any other.

**Show query plan** looks the plan up in the plan cache first and then in Query Store in any database where it is on, so a plan that has left the cache can still be found. Plans are never collected on a schedule; this job is how to get one. From the Query History page it runs behind the **Show plan** button and offers the result as a `.sqlplan` download that SQL Server Management Studio opens as a graphical plan. When no plan is found the job's message says why where it can: no such database, the database is not online or the monitoring login cannot open it, Query Store is off there, or the error the database raised.

## Before jobs will run {#prerequisites}

Three things must be in place per target. **Monitoring credentials are not enough** — a target that is Up and collecting proves nothing about whether its jobs will run, because jobs use a different credential path entirely.

**1. A host credential on the SQL Server target.** The jobs run through a remote operation on the agent, so they need a host credential — set as a Preferred Credential on the **SQL Server Database target type**, not on the host target type. The set does not exist on the host type, and attempting it there is rejected.

**2. A populated truststore credential set — on every target.** The jobs read the truststore through Enterprise Manager's credential system, and the lookup has to resolve on every target, including targets that do not use one.

- Target verifying a certificate: enter the real path, type and password.
- Every other target: enter the literal value `none` in all three fields. The plug-in reads a truststore path of `none` as "no client truststore".

A job against a target whose truststore set is empty fails with an unresolved credential reference. Set the `none` values during target onboarding and this never comes up.

**3. The right grant for the job.** See below.

The practical advice: set both credential sets when you onboard a target, alongside its monitoring credentials. Then console actions work from day one instead of failing the first time somebody tries one.

## Grants each job needs {#grants}

These are **in addition** to the read-only monitoring grants. The monitoring login is deliberately not able to do any of this by default.

| Job | Grant |
| :--- | :--- |
| Back up database, schedule backup | `db_backupoperator` in the target database |
| Restore, restore full | `dbcreator` |
| Create index | `db_ddladmin` in the target database |
| Show query plan | None beyond the monitoring login; the job is read-only |
| Kill session | `ALTER ANY CONNECTION` |
| AlwaysOn failover | `ALTER AVAILABILITY GROUP` |
| Delete backup | `sysadmin` — see below |

A log backup additionally needs the database in the full recovery model with a prior full backup, which is a SQL Server requirement rather than a plug-in one.

**Delete backup is intentionally outside the least-privilege model.** It calls an `msdb` procedure that SQL Server itself restricts to `sysadmin`. Rather than push the monitoring login up to `sysadmin` for one job, submit that job with override credentials when you need it.

## Things that catch people out {#gotchas}

**A healthy target says nothing about jobs.** Monitoring credentials and job credentials are separate mechanisms. A target can collect happily for months and still fail the first job submitted against it, because the host credential was never set.

**Testing by command line can mislead you.** A job submitted from `emcli` with credentials bound explicitly bypasses preferred credentials altogether. It will succeed while the same job from the console fails, because the console relies on the preferred credential that was never configured. If you are verifying that jobs work, verify from the console.

**Create index needs the three-part name.** The job runs in the monitoring login's default database, usually `master`. Give `database.schema.table`, for example `Sales.dbo.Orders`. A two-part `schema.table` is resolved in the default database, not in a database of that name: it fails with "Cannot find the object" when nothing matches there, and if a matching object does exist in the default database the index is created there instead, which is rarely what was intended. The Create Index dialog on the Indexes page has a separate Database field, builds the three-part name for you, and rejects a table name that omits the schema.

**Restore is for a database that does not exist yet.** Restore database issues `NORECOVERY`, and restoring over a live full-recovery database is refused by SQL Server's tail-log protection, by design. To overwrite a live database use Restore full database, which issues `WITH REPLACE, RECOVERY`.

**AlwaysOn failover runs on the secondary.** Submit it against a target scoped to the secondary replica being promoted. A listener target always routes to the primary and cannot perform its own failover.

**Service stop order on Windows.** Stop SQL Server Agent before the instance, and start in the reverse order. The stop job surfaces the WMI return code when the order is violated. The service jobs are Windows-only.

**A job parameter value cannot smuggle in a second argument.** Every parameter value is checked before the job hands it to the agent, and a value that would add, repeat or reorder an argument fails the step with a message naming the parameter. A comma inside a value is kept as part of the value, so a comma-separated Create Index column list reaches the job whole.

## Backups use native T-SQL {#native-tsql}

The backup and restore jobs use native T-SQL backup and restore. They do not use `xp_cmdshell`, and the plug-in never asks you to enable it.

This matters because the plug-in also flags `xp_cmdshell` as a compliance finding. It would be poor form to warn about a setting and then require it — so it does not.

## Related

- [Credentials](credentials.md#grants) - the monitoring login, and why jobs need more than it
- [TLS connections](tls.md) - the truststore every job resolves, whether or not you use TLS
- [Monitoring pages](monitoring-pages.md#databases) - the Databases page, where backup and restore are submitted
- [Monitoring pages](monitoring-pages.md#query-history) - the Show plan action on Query History
- [Troubleshooting](troubleshooting.md#jobs) - a job that fails with no obvious cause
