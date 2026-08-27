---
title: Jobs
nav_order: 22
---

# Jobs

The plug-in ships ten Enterprise Manager job types, so the things you find on a monitoring page can be acted on from the same console — with Enterprise Manager's own scheduling, credentials and audit trail.

> **Prerequisites for this page**
> - Job credentials set on the target. These are separate from monitoring credentials: a target that is Up and collecting tells you nothing about whether its jobs will run. See [Before jobs will run](#prerequisites).
> - The truststore credential set resolved on every target, including targets with no truststore, where it takes the literal value `none`.
> - Grants beyond the monitoring login for most jobs. See [Grants each job needs](#grants).

**In this page:** The jobs · Before jobs will run · Grants each job needs · Two things that catch people out · Backups use native T-SQL

## The jobs {#the-jobs}

| Job | Does |
| :--- | :--- |
| Back up database | A native T-SQL backup |
| Restore database | Restores, leaving the database ready for further backups to be applied |
| Restore full database | Restores and brings the database online |
| Delete backup | Removes a backup history entry |
| Create index | Creates an index, typically one the Indexes page has suggested |
| Kill session | Ends a session |
| AlwaysOn failover | Fails an availability group over |
| Start instance | Starts the SQL Server service |
| Stop instance | Stops it |
| Pause / resume instance | Pauses or resumes it |

They are ordinary Enterprise Manager jobs. They can be scheduled, they appear in Job Activity, and they are audited like any other.

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
| Back up database | `db_backupoperator` in the target database |
| Restore, restore full | `dbcreator` |
| Create index | `db_ddladmin` in the target database |
| Kill session | `ALTER ANY CONNECTION` |
| AlwaysOn failover | `ALTER AVAILABILITY GROUP` |
| Delete backup | `sysadmin` — see below |

A log backup additionally needs the database in the full recovery model with a prior full backup, which is a SQL Server requirement rather than a plug-in one.

**Delete backup is intentionally outside the least-privilege model.** It calls an `msdb` procedure that SQL Server itself restricts to `sysadmin`. Rather than push the monitoring login up to `sysadmin` for one job, submit that job with override credentials when you need it.

## Two things that catch people out {#gotchas}

**A healthy target says nothing about jobs.** Monitoring credentials and job credentials are separate mechanisms. A target can collect happily for months and still fail the first job submitted against it, because the host credential was never set.

**Testing by command line can mislead you.** A job submitted from `emcli` with credentials bound explicitly bypasses preferred credentials altogether. It will succeed while the same job from the console fails, because the console relies on the preferred credential that was never configured. If you are verifying that jobs work, verify from the console.

## Backups use native T-SQL {#native-tsql}

The backup and restore jobs use native T-SQL backup and restore. They do not use `xp_cmdshell`, and the plug-in never asks you to enable it.

This matters because the plug-in also flags `xp_cmdshell` as a compliance finding. It would be poor form to warn about a setting and then require it — so it does not.

## Related

- [Credentials](credentials.html#grants) - the monitoring login, and why jobs need more than it
- [TLS connections](tls.html) - the truststore every job resolves, whether or not you use TLS
- [Monitoring pages](monitoring-pages.html#databases) - the Databases page, where backup and restore are submitted
- [Troubleshooting](troubleshooting.html#jobs) - a job that fails with no obvious cause
