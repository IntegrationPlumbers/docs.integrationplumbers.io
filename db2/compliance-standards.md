---
title: Compliance standards
nav_order: 9
---

# Compliance standards

The plug-in ships three compliance standards with 29 rules for IBM Db2 databases. They cover configuration best practices, audit posture with authorities and privileges, and the Db2 version lifecycle. This page explains what ships, how to switch it on, what to expect when you upgrade from GA, and what every rule checks. It is for the administrator who associates the standards and the DBA who acts on their findings.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS. Deploying it installs the compliance content, with no separate registration step.
> - At least one database target's daily configuration collection has run, for the rules to have anything to evaluate. See [Let a configuration collection run](#let-a-configuration-collection-run).
> - On a hardened database only: the optional catalog grants under [A hardened database](#hardened-database).

**Where to find it:** **Enterprise → Compliance → Library** (the standards, rules and framework), and **Enterprise → Compliance → Results**.

**In this page:** What ships · Scores drop after upgrading from GA · Associate a standard with targets · Let a configuration collection run · Read results · A hardened database · Rule parameters · Rules by standard

## What ships {#what-ships}

The rules are evaluated in the Enterprise Manager repository on the daily configuration snapshot the plug-in already collects. On a default Db2 installation they need nothing beyond the least-privilege monitoring user (`CONNECT` and `SQLADM`) that everything else on this site uses.

| Standard | Internal name | Version | Rules | What it checks |
| :--- | :--- | :---: | :---: | :--- |
| **IBM Db2 Database Configuration Best Practices** | `ip_db2_config_best_practices` | 2 | 17 | Diagnostic logging, recovery (archive logging, backup protection, retention and recency, resync interval), memory, network and platform security (TLS), authentication and access, and maintenance and concurrency |
| **IBM Db2 Database Audit Posture** | `ip_db2_audit_posture` | 1 | 10 | An audit policy exists, is attached and covers the core categories; audit records are written asynchronously; SYSADM belongs to a named group; and authorities and privileges granted to `PUBLIC` and to administrators |
| **IBM Db2 Database Version Lifecycle** | `ip_db2_version_lifecycle` | 1 | 2 | The Db2 release is not past IBM end of support, and the server runs the latest modification pack of its release |

- **One framework** collects the three standards: **IBM Db2 Database Compliance Framework**. To check that the content installed, open **Enterprise → Compliance → Library** and look for the three standards and the framework.
- **All 29 rules target IBM Db2 Database targets** (`ip_db2_database`), and each belongs to exactly one standard. No rule evaluates IBM Db2 Instance targets.
- **Severity** is what a violation raises: 9 rules are Critical, 17 are Warning and 3 are Minor Warning.
- **Importance** (High, Normal or Low) is how heavily a rule weighs in its standard's compliance score.
- **All three are authored by `SYSMAN`.** No standard is evaluated until you associate it with targets.

This release adds twelve rules to the 17 of the GA release: client authentication, TLS offered but not enforced, `CATALOG_NOAUTH`, `LOCKTIMEOUT` -1, automatic RUNSTATS off, backup retention, backup recency, and five authorities and privileges rules.

## Scores drop after upgrading from GA {#score-drop}

**Expect compliance scores to drop on each database's first configuration collection after the upgrade.** Three of the new rules check settings that most databases have:

- **`LOCKTIMEOUT` -1**, which is Db2's default (Lock Waits Never Time Out, `ip_db2_locktimeout_infinite`, Warning).
- **`CREATETAB`, `BINDADD` and `IMPLICIT_SCHEMA` held by `PUBLIC`**, which Db2 grants on every database not created `RESTRICTIVE` (Default Database Privileges Still Granted to PUBLIC, `ip_db2_public_default_privileges`, Warning).
- **A last backup older than 7 days**, or no backup at all, which includes most development databases (Database Backup Older Than Policy, `ip_db2_backup_too_old`, Critical).

So nearly every associated database gains the two Warnings, and many gain the Critical. Enterprise Manager's out-of-box incident rule set opens an incident when a compliance score drops (see [Incident rules](alerts-and-templates.md#incident-rules)). That is the rules working.

Before the upgrade reaches production, decide for each of these rules whether to fix the setting, change the rule's parameter for the targets that follow a different policy (see [Rule parameters](#parameters)), or narrow the standard's target association. The other upgrade steps are on [Upgrade notes](upgrade-notes.md#update-24-1-2).

The new rules report nothing until each target's first configuration collection on this release: until then the tables they read are empty, and a rule with no data raises no violation.

## Associate a standard with targets {#associate}

**Nothing evaluates until you do this.** An installed standard with no associated targets is the usual reason the compliance dashboard shows an empty Db2 bar.

In the console:

1. Go to **Enterprise → Compliance → Library**, and open the **Compliance Standards** tab.
2. Select a standard, then **Associate Targets**, and add your IBM Db2 Database targets.
3. Repeat for the other two standards.

With EM CLI, scriptable across as many targets as you like, once per standard, with the version the Library shows:

```
emcli associate_cs_targets -name="ip_db2_config_best_practices" -version=2 -author=SYSMAN \
      -target_list="<target1>,<target2>"
emcli associate_cs_targets -name="ip_db2_version_lifecycle" -version=1 -author=SYSMAN \
      -target_list="<target1>,<target2>"
emcli associate_cs_targets -name="ip_db2_audit_posture" -version=1 -author=SYSMAN \
      -target_list="<target1>,<target2>"
```

Add `-force` to evaluate again at once, for example after a configuration change. The standards keep their GA names and versions (2, 1 and 1) in this release.

## Let a configuration collection run {#let-a-configuration-collection-run}

The rules read the plug-in's configuration snapshot, which collects once every 24 hours. They stay empty until a target's snapshot has been collected at least once. A newly associated standard on a new target legitimately shows nothing until that first collection; that is not a broken check. To collect at once, run **Configuration → Refresh** on the target.

**Backup recency follows the daily snapshot.** The snapshot records the age of the last backup when it is collected, and Enterprise Manager checks the rule again when that age changes. A violation therefore opens, or clears after a backup, at the next daily configuration collection, up to a day late. Run the target's configuration collection to see it at once. Between snapshots, the `DB_Backup : days_since_last_backup` alert is the signal (see [Default thresholds](alerts-and-templates.md#default-thresholds)).

## Read results {#read-results}

Open **Enterprise → Compliance → Results**. Each standard reports Targets Evaluated, Violations (by severity), and a Score.

- **A first result is a baseline.** A freshly associated, unhardened database often shows findings on Configuration Best Practices and Audit Posture on the first pass. Many environments have not tuned every configuration check, and many have no audit policy at all. Treat the first result as the list to work from, not a defect in the plug-in.
- **Version Lifecycle at 100%** means every monitored database is on an in-support release at its latest modification pack (by default 11.5.9 or 12.1.5). That is the expected result on a current estate. A database one or more modification packs behind is flagged even while its release is still in support.
- **Instance settings repeat on every database.** `AUTHENTICATION`, `SRVCON_AUTH`, `CATALOG_NOAUTH` and `DB2COMM` belong to the instance, not the database, so every database target of a non-compliant instance shows the same violation. Four databases on one instance with `CATALOG_NOAUTH` on are one problem to fix, not four.
- **One audit-policy finding at a time.** The first three Audit Posture rules exclude each other: a database has no policy, or a policy not attached, or an attached policy with a core category off.
- **A rule with no data reports no violation.** If a configuration group cannot read the catalog (see [A hardened database](#hardened-database)), its rules have nothing to evaluate and the score does not drop. Check CollectorStatus on the target, not the score.

## A hardened database {#hardened-database}

On a default Db2 installation, `SELECT` on the `SYSCAT` catalog views is granted to `PUBLIC`, so the monitoring user reads everything the rules need. Security baselines (the DISA STIG for Db2 LUW among them) recommend revoking `PUBLIC` from some of these views, and a database created `RESTRICTIVE` does not grant the catalog to `PUBLIC` at all. There, grant the monitoring user the views below. The examples use `oem_monitor`, as [The monitoring role](prerequisites.md#monitoring-role) does.

**Audit Posture: the audit configuration.** The audit-posture rules read the audit policies and what they are attached to:

```sql
GRANT SELECT ON TABLE SYSCAT.AUDITPOLICIES TO USER oem_monitor;
GRANT SELECT ON TABLE SYSCAT.AUDITUSE      TO USER oem_monitor;
```

These give no access to audit records: the plug-in reads which policies exist, what they are attached to and which categories they cover, never the audit log, and it needs no `SECADM` authority. Without the grant, the audit-posture collection reports an authorization error on that one metric, and the audit-posture rules have no data to evaluate. Every other collection is unaffected.

**Audit Posture: authorities and privileges (optional).** The five privilege rules read one daily summary of who holds which authority and what is granted to `PUBLIC`:

```sql
GRANT SELECT ON TABLE SYSCAT.DBAUTH           TO USER oem_monitor;
GRANT SELECT ON TABLE SYSCAT.TABAUTH          TO USER oem_monitor;
GRANT SELECT ON TABLE SYSCAT.ROUTINEAUTH      TO USER oem_monitor;
GRANT SELECT ON TABLE SYSCAT.CONTEXTS         TO USER oem_monitor;
GRANT SELECT ON TABLE SYSCAT.SURROGATEAUTHIDS TO USER oem_monitor;
```

These show who holds which authority and which objects are granted to `PUBLIC`, by name. They give no authority and no access to any table's data. The grant is optional: without it the *Database Authorities and Privileges* group collects nothing and CollectorStatus reports it `NOT_CONFIGURED`, naming the grant, with no collection error and no alert. The five privilege rules then evaluate nothing for that database, and a privilege violation that was already open is expected to clear because its row is gone, not because anything was fixed.

## Rule parameters {#parameters}

Ten rules compare against a parameter rather than a fixed value, so a site whose policy differs can change the value for the targets that follow it.

| Rule | Parameter | Default | Violation when |
| :--- | :--- | :---: | :--- |
| Diagnostic Error Capture Level Below Recommended | `MIN_DIAGLEVEL` | 3 | `DIAGLEVEL` is below it |
| Notify Level Below Recommended | `MIN_NOTIFYLEVEL` | 2 | `NOTIFYLEVEL` is below it |
| Transaction Resync Interval Above Recommended | `MAX_RESYNC_INTERVAL` | 180 | `RESYNC_INTERVAL` (seconds) is above it |
| Backup Retention Too Short | `MIN_DB_BACKUPS` | 2 | `NUM_DB_BACKUPS` is below it |
| Backup Retention Too Short | `MIN_HISTORY_DAYS` | 30 | `REC_HIS_RETENTN` (days) is below it; -1 is not checked |
| Database Backup Older Than Policy | `MAX_BACKUP_AGE_DAYS` | 7 | The last backup is older than this many days, or the database was never backed up |
| Too Many DBADM or SECADM Holders | `MAX_DBADM_HOLDERS` | 3 | More grantees hold DBADM (a group or role counts as one) |
| Too Many DBADM or SECADM Holders | `MAX_SECADM_HOLDERS` | 2 | More grantees hold SECADM |
| Modification Pack Behind the Latest for Its Release | `MIN_MOD_115` | 9 | A Db2 11.5 server is below modification pack 11.5.9 |
| Modification Pack Behind the Latest for Its Release | `MIN_MOD_121` | 5 | A Db2 12.1 server is below modification pack 12.1.5 |

## Rules by standard {#rules}

Each rule below gives its name as the console shows it, its internal name, its severity and importance, what it checks, why it matters, and the fix. The fix examples use a database named `SALES` and an instance named `DB2INST1`; substitute your own.

| Standard | Rule folder | Rules | Critical | Warning | Minor Warning |
| :--- | :--- | :---: | :---: | :---: | :---: |
| Configuration Best Practices | Diagnostic Logging | 3 | 0 | 2 | 1 |
| Configuration Best Practices | Recovery | 5 | 2 | 3 | 0 |
| Configuration Best Practices | Memory | 2 | 1 | 0 | 1 |
| Configuration Best Practices | Network and Platform Security | 3 | 0 | 2 | 1 |
| Configuration Best Practices | Authentication and Access | 2 | 1 | 1 | 0 |
| Configuration Best Practices | Maintenance and Concurrency | 2 | 0 | 2 | 0 |
| Audit Posture | Audit Posture | 3 | 2 | 1 | 0 |
| Audit Posture | Audit Delivery and Administrative Authority | 2 | 0 | 2 | 0 |
| Audit Posture | Authorities and Privileges | 5 | 2 | 3 | 0 |
| Version Lifecycle | Version End of Support | 1 | 1 | 0 | 0 |
| Version Lifecycle | Modification Pack Currency | 1 | 0 | 1 | 0 |
| **Total** | | **29** | **9** | **17** | **3** |

### IBM Db2 Database Configuration Best Practices (17 rules) {#rules-config}

#### Diagnostic Error Capture Level Below Recommended

`ip_db2_diaglevel_below_recommended` · Warning · importance Normal · folder Diagnostic Logging · parameter `MIN_DIAGLEVEL` (3)

**Checks:** that the database manager `DIAGLEVEL` captures at least all errors and warnings.

**Why it matters:** messages below the capture level are never written to db2diag.log. Below 3, the warnings that precede an outage (a full log, failing backups, storage problems) leave no trace, and the plug-in's diagnostic-log monitoring has nothing to match.

**Fix:** `db2 update dbm cfg using DIAGLEVEL 3` (the Db2 default). Raise it to 4 only while troubleshooting: level 4 logs informational messages and can slow processing.

#### Notify Level Below Recommended

`ip_db2_notifylevel_below_recommended` · Warning · importance Normal · folder Diagnostic Logging · parameter `MIN_NOTIFYLEVEL` (2)

**Checks:** that `NOTIFYLEVEL` records at least the conditions that need immediate administrator action.

**Why it matters:** below 2, a failed backup, a full transaction log or a health indicator in alarm is never written to the administration notification log, so nobody is told.

**Fix:** `db2 update dbm cfg using NOTIFYLEVEL 3` (the Db2 default), or no less than 2.

#### Diagnostic Data Directory Path Not Set

`ip_db2_diagpath_not_set` · Minor Warning · importance Low · folder Diagnostic Logging

**Checks:** that `DIAGPATH` names an explicit diagnostic data directory.

**Why it matters:** unset, db2diag.log goes to the instance default directory, which may be on a file system not sized, monitored or backed up for it.

**Fix:** `db2 update dbm cfg using DIAGPATH /path/to/diag`, on a file system sized for diagnostic data.

#### Circular Logging Leaves Database Without Rollforward Recovery

`ip_db2_circular_logging_no_recovery` · Critical · importance High · folder Recovery

**Checks:** that the database uses archive logging (`LOGARCHMETH1`), not circular logging.

**Why it matters:** with circular logging the logs are reused and never archived, so the database cannot be rolled forward. The only recovery is an offline restore of the last full backup, losing everything committed since.

**Fix:** `db2 update db cfg for SALES using LOGARCHMETH1 DISK:/db2/archive` (or a TSM or vendor method), then take an offline full backup to clear the backup-pending state.

#### Automatic Backup or Modified-Page Tracking Disabled

`ip_db2_backup_protection_disabled` · Warning · importance Normal · folder Recovery

**Checks:** that automatic backup (`AUTO_DB_BACKUP`) and modified-page tracking (`TRACKMOD`, needed for incremental and delta backups) are both on.

**Why it matters:** without `AUTO_DB_BACKUP`, protection depends entirely on an external schedule that can lapse. Without `TRACKMOD`, only full backups are possible, with longer windows and more storage.

**Fix:** `db2 update db cfg for SALES using AUTO_DB_BACKUP ON`, with a configured backup target; where incremental backups are wanted, `db2 update db cfg for SALES using TRACKMOD ON`, then a full backup to baseline it.

#### Transaction Resync Interval Above Recommended

`ip_db2_resync_interval_above_recommended` · Warning · importance Normal · folder Recovery · parameter `MAX_RESYNC_INTERVAL` (180)

**Checks:** that `RESYNC_INTERVAL` does not delay resolving indoubt transactions.

**Why it matters:** an indoubt transaction left by an interrupted two-phase commit holds its locks and log space for the whole interval, so other applications block and log space cannot be reclaimed.

**Fix:** `db2 update dbm cfg using RESYNC_INTERVAL 180` (the Db2 default) or less.

#### Backup Retention Too Short

`ip_db2_backup_retention_low` · Warning · importance Normal · folder Recovery · parameters `MIN_DB_BACKUPS` (2), `MIN_HISTORY_DAYS` (30)

**Checks:** that the recovery history keeps at least `MIN_DB_BACKUPS` full backups (`NUM_DB_BACKUPS`) for at least `MIN_HISTORY_DAYS` days (`REC_HIS_RETENTN`; -1 is not checked).

**Why it matters:** Db2 expires backups and history beyond these limits, and with `AUTO_DEL_REC_OBJ ON` deletes the images and logs. If the only retained backup is unusable, there is nothing to restore from.

**Fix:** keep at least two full backups and a history that covers your recovery window, for example `db2 update db cfg for SALES using NUM_DB_BACKUPS 4 REC_HIS_RETENTN 35`. Change the parameters where your policy differs.

#### Database Backup Older Than Policy

`ip_db2_backup_too_old` · Critical · importance High · folder Recovery · parameter `MAX_BACKUP_AGE_DAYS` (7)

**Checks:** that the last successful backup is no older than `MAX_BACKUP_AGE_DAYS` days, and that the database has been backed up at all. It is checked on each daily configuration snapshot, against the backup's age when the snapshot was collected.

**Why it matters:** a restore goes back to the last backup and rolls forward through every log archived since. The older the backup, the longer the restore and the more is lost if one log is missing. A database never backed up cannot be restored.

**Fix:** take a backup now (`db2 backup db SALES online include logs`, or the Online Backup job) and schedule one at least as often as the parameter. The violation clears at the next daily configuration collection; run the target's configuration collection to clear it sooner.

#### Database System Monitor Heap Disabled

`ip_db2_mon_heap_disabled` · Critical · importance High · folder Memory

**Checks:** that `MON_HEAP_SZ` allocates memory for database system monitor data.

**Why it matters:** at 0 the monitor heap is disabled, the `MON_GET_*` table functions the plug-in reads return nothing, and the target goes dark in Enterprise Manager: metrics stop, so alerts that depend on them cannot fire.

**Fix:** `db2 update dbm cfg using MON_HEAP_SZ AUTOMATIC`. Restart the instance if the change is deferred.

#### Sort Heap Threshold Prevents Sort Memory Tuning

`ip_db2_sheapthres_blocks_sort_tuning` · Minor Warning · importance Low · folder Memory

**Checks:** that `SHEAPTHRES` is 0, so sort memory is managed under the shared sort memory model.

**Why it matters:** a non-zero `SHEAPTHRES` keeps the instance on the private model, and the self-tuning memory manager cannot tune `SORTHEAP` or `SHEAPTHRES_SHR`, even when both are `AUTOMATIC`.

**Fix:** `db2 update dbm cfg using SHEAPTHRES 0`, then set `SHEAPTHRES_SHR` and `SORTHEAP` to `AUTOMATIC` with `SELF_TUNING_MEM ON`.

#### Database Accepts Only Unencrypted Network Connections

`ip_db2_db2comm_without_ssl` · Warning · importance High · folder Network and Platform Security

**Checks:** that an instance listening for TCP/IP (`DB2COMM` includes `TCPIP`) also offers TLS (`DB2COMM` includes `SSL`).

**Why it matters:** without a TLS listener every remote connection is unencrypted: SQL text, result data and, depending on the authentication type, credentials can be read on the network.

**Fix:** configure TLS on the instance (keystore, `SSL_SVR_KEYDB`, `SSL_SVR_STASH`, `SSL_SVR_LABEL`, `SSL_SVCENAME`), run `db2set DB2COMM=TCPIP,SSL`, restart the instance and move clients to the TLS port.

#### Windows Extended Security Turned Off

`ip_db2_extsecurity_off_windows` · Warning · importance High · folder Network and Platform Security

**Checks:** that Db2 extended security (`DB2_EXTSECURITY`) has not been turned off on a Windows server.

**Why it matters:** with `DB2_EXTSECURITY=NO`, any local Windows user can read or change the Db2 installation, database files and registry keys, bypassing the `DB2ADMNS` and `DB2USERS` groups.

**Fix:** run `db2extsec` (for example `db2extsec -a DB2ADMNS -u DB2USERS`), which sets `DB2_EXTSECURITY=YES` and reapplies the access controls, then restart the instance.

#### TLS Offered but Not Enforced

`ip_db2_tls_not_enforced` · Minor Warning · importance Normal · folder Network and Platform Security

**Checks:** that an instance offering TLS (`DB2COMM` includes `SSL`) does not also accept unencrypted TCP/IP connections (`DB2COMM` includes `TCPIP`).

**Why it matters:** while the plain listener stays open, any client can still connect without TLS. Offering TLS protects only the clients that choose it.

**Fix:** move every client to the TLS port, then `db2set DB2COMM=SSL` and restart the instance. Keep `TCPIP` only while a client that cannot use TLS remains, and record that exception.

#### Users Authenticated by the Client, Not the Server

`ip_db2_client_authentication` · Critical · importance High · folder Authentication and Access

**Checks:** that neither `AUTHENTICATION` nor `SRVCON_AUTH` is `CLIENT`.

**Why it matters:** with `CLIENT` authentication Db2 accepts the user ID the client presents without checking a password at the server. Anyone who controls a client machine connects as that user, including one with administrative authority.

**Fix:** `db2 update dbm cfg using AUTHENTICATION SERVER_ENCRYPT` (and `SRVCON_AUTH SERVER_ENCRYPT`, or `NOT_SPECIFIED` to follow `AUTHENTICATION`), then restart the instance. For a central identity, use `KERBEROS` or a GSS plug-in. Check that client applications can authenticate before the change.

#### Users Without Authority Can Catalog Databases

`ip_db2_catalog_noauth_enabled` · Warning · importance Normal · folder Authentication and Access

**Checks:** that cataloging databases, nodes and DCS entries needs SYSADM (`CATALOG_NOAUTH` is `NO`).

**Why it matters:** with `CATALOG_NOAUTH` set to `YES`, any user on the server can change the instance's directories, for example to point a database alias at another server and collect the credentials of users who connect to it.

**Fix:** attach to the instance (`db2 attach to DB2INST1`), then `db2 update dbm cfg using CATALOG_NOAUTH NO immediate`. Made without an attachment, the change applies only at the next `db2stop` and `db2start`, and the rule, which reads the value in effect, still reports `YES` until then.

#### Lock Waits Never Time Out

`ip_db2_locktimeout_infinite` · Warning · importance Normal · folder Maintenance and Concurrency

**Checks:** that the database sets a lock timeout (`LOCKTIMEOUT` is not -1). -1 is Db2's default.

**Why it matters:** with -1, a session waiting for a lock held by an idle or stuck transaction waits until that transaction ends. Waits pile up, connections and agents run out, and the application appears hung with no error to report or retry.

**Fix:** set a timeout suited to the workload, for example `db2 update db cfg for SALES using LOCKTIMEOUT 60` for online work. Applications then receive `SQL0911N` reason code 68 and can retry; a session that needs another value can use `SET CURRENT LOCK TIMEOUT`.

#### Automatic Statistics Collection Off

`ip_db2_auto_maintenance_off` · Warning · importance Normal · folder Maintenance and Concurrency

**Checks:** that automatic maintenance is on down to automatic RUNSTATS (`AUTO_MAINT`, `AUTO_TBL_MAINT` and `AUTO_RUNSTATS` all `ON`).

**Why it matters:** without automatic RUNSTATS, the optimizer works from stale row counts and distributions and chooses poor access plans, often suddenly after a data load.

**Fix:** `db2 update db cfg for SALES using AUTO_MAINT ON AUTO_TBL_MAINT ON AUTO_RUNSTATS ON`. If a scheduled job collects statistics instead, keep its schedule under review and exclude this database from the rule.

### IBM Db2 Database Audit Posture (10 rules) {#rules-audit}

#### No Db2 Audit Policy Is Defined

`ip_db2_audit_no_policy_defined` · Critical · importance High · folder Audit Posture

**Checks:** that at least one audit policy is defined in the database (`SYSCAT.AUDITPOLICIES`).

**Why it matters:** with no policy, Db2 records nothing: privilege grants, failed authorization checks, administrative actions and changes to the audit configuration itself leave no trace.

**Fix:** define a policy and attach it, for example `CREATE AUDIT POLICY dbpolicy CATEGORIES AUDIT STATUS BOTH, CHECKING STATUS BOTH, SECMAINT STATUS BOTH, SYSADMIN STATUS BOTH ERROR TYPE AUDIT`, then `AUDIT DATABASE USING POLICY dbpolicy`.

#### Db2 Audit Policy Is Defined But Not Attached To The Database

`ip_db2_audit_policy_not_assigned` · Critical · importance High · folder Audit Posture

**Checks:** that an audit policy is attached to the database (`SYSCAT.AUDITUSE`), not merely defined.

**Why it matters:** a policy that is never attached audits nothing. Its categories can look correct in a review while Db2 records no audit events for the database.

**Fix:** `AUDIT DATABASE USING POLICY <policy-name>`. Confirm with `SELECT * FROM SYSCAT.AUDITUSE WHERE OBJECTTYPE = ' '`.

#### Db2 Audit Policy Leaves Core Categories Unaudited

`ip_db2_audit_categories_not_covered` · Warning · importance Normal · folder Audit Posture

**Checks:** that the attached audit policy audits the core categories: `AUDIT`, `CHECKING`, `SECMAINT` and `SYSADMIN`.

**Why it matters:** a category set to `NONE` records nothing. Without `AUDIT`, changes to the audit policy go unrecorded; without `CHECKING`, failed access attempts; without `SECMAINT`, privilege grants; without `SYSADMIN`, administrative actions.

**Fix:** `ALTER AUDIT POLICY <policy-name> CATEGORIES AUDIT STATUS BOTH, CHECKING STATUS BOTH, SECMAINT STATUS BOTH, SYSADMIN STATUS BOTH ERROR TYPE AUDIT`.

#### Audit Records Written Synchronously

`ip_db2_audit_buffer_synchronous` · Warning · importance Normal · folder Audit Delivery and Administrative Authority

**Checks:** that a database with an attached audit policy has an audit buffer (`AUDIT_BUF_SZ` above 0), so audit records are written asynchronously.

**Why it matters:** at 0 every audited statement waits until its audit record is on disk. On a busy database that slows the audited work, and turning auditing off to recover performance leaves no audit trail.

**Fix:** `db2 update dbm cfg using AUDIT_BUF_SZ 1000` (pages of 4 KB, sized for your audit volume), then restart the instance. Keep 0 only where policy requires that no audit record can ever be lost.

#### SYSADM Authority Falls Back to an Operating System Default

`ip_db2_sysadm_group_not_set` · Warning · importance High · folder Audit Delivery and Administrative Authority

**Checks:** that `SYSADM_GROUP` names a dedicated group.

**Why it matters:** unset, SYSADM goes to every local Administrator on Windows, or every member of the instance owner's primary group on Linux and UNIX. Anyone added to those groups for another reason becomes a Db2 system administrator.

**Fix:** create a dedicated operating system group with only the people and service accounts that need SYSADM, then `db2 update dbm cfg using SYSADM_GROUP <group>` and restart the instance.

#### Authority Beyond the Defaults Granted to PUBLIC

`ip_db2_public_admin_authority` · Critical · importance High · folder Authorities and Privileges

**Checks:** that `PUBLIC` holds no database authority other than the defaults `BINDADD`, `CONNECT`, `CREATETAB` and `IMPLICIT_SCHEMA` (for example no `DBADM`, `SECADM`, `DATAACCESS`, `ACCESSCTRL`, `SQLADM`, `LOAD` or `CREATE_EXTERNAL_ROUTINE`).

**Why it matters:** an authority granted to `PUBLIC` is held by every user who can connect, now and in future.

**Fix:** revoke each listed authority from `PUBLIC` and grant it to the roles or groups that need it, for example `db2 "REVOKE DBADM ON DATABASE FROM PUBLIC"` and `db2 "GRANT DBADM ON DATABASE TO ROLE DBA_ROLE"`. Check which applications depend on it first; `SYSCAT.DBAUTH` lists every holder.

#### Trusted Context Lets Any User Switch In Without Authentication

`ip_db2_trusted_context_public_noauth` · Critical · importance High · folder Authorities and Privileges

**Checks:** that no enabled user-defined trusted context lets `PUBLIC` switch user without authentication (`WITH USE FOR PUBLIC WITHOUT AUTHENTICATION`). Db2's own `SYSATSCONTEXT`, created with every database for the Administrative Task Scheduler, is not counted while it has no default role.

**Why it matters:** whoever controls a connection that matches the context can act as any user of the database, and the audit trail records the assumed user.

**Fix:** require authentication or name the users, for example `db2 "ALTER TRUSTED CONTEXT APPCTX REPLACE USE FOR PUBLIC WITH AUTHENTICATION"`. Restrict the context's `ADDRESS` attribute to the application servers, and require `ENCRYPTION`.

#### Default Database Privileges Still Granted to PUBLIC

`ip_db2_public_default_privileges` · Warning · importance Normal · folder Authorities and Privileges

**Checks:** that `PUBLIC` no longer holds `CREATETAB`, `BINDADD` or `IMPLICIT_SCHEMA`, which a database created without `RESTRICTIVE` grants it. `CONNECT` alone is accepted.

**Why it matters:** with these defaults any user who can connect can create tables, bind packages and create schemas: fill table spaces, shadow application objects, and bind code that runs with the privileges of whoever executes it.

**Fix:** `db2 "REVOKE CREATETAB, BINDADD, IMPLICIT_SCHEMA ON DATABASE FROM PUBLIC"`, and grant them only to the roles that create objects. A new database avoids them with `CREATE DATABASE ... RESTRICTIVE`.

#### User Tables or Views Granted to PUBLIC

`ip_db2_public_table_privileges` · Warning · importance Normal · folder Authorities and Privileges

**Checks:** that no user table or view (outside Db2's own schemas) has a privilege granted to `PUBLIC`.

**Why it matters:** every user who can connect, including accounts created later for unrelated purposes, can read the data, and with a write privilege change or delete it.

**Fix:** grant to roles, then revoke the `PUBLIC` grants, for example `db2 "GRANT SELECT ON APP.ORDERS TO ROLE APP_READ"` and `db2 "REVOKE ALL ON APP.ORDERS FROM PUBLIC"`. The violation names the first tables; `SYSCAT.TABAUTH WHERE GRANTEE = 'PUBLIC'` lists them all.

#### Too Many DBADM or SECADM Holders

`ip_db2_admin_authority_holders` · Warning · importance Normal · folder Authorities and Privileges · parameters `MAX_DBADM_HOLDERS` (3), `MAX_SECADM_HOLDERS` (2)

**Checks:** that no more than `MAX_DBADM_HOLDERS` grantees hold DBADM and no more than `MAX_SECADM_HOLDERS` hold SECADM. A group or role counts as one grantee.

**Why it matters:** DBADM gives full control of the database; SECADM controls who can do what. Every extra direct holder is another account that can do all of that, and grants to individuals outlive the job they were made for.

**Fix:** grant each authority to one role or group and revoke direct grants, for example `db2 "REVOKE DBADM ON DATABASE FROM USER JSMITH"`. Keep SECADM separate from DBADM where policy asks for separation of duties, and set the parameters to the numbers your site approves.

### IBM Db2 Database Version Lifecycle (2 rules) {#rules-lifecycle}

#### Db2 Release Is Past IBM End of Support

`ip_db2_version_past_end_of_support` · Critical · importance High · folder Version End of Support

**Checks:** that the installed Db2 release is still within IBM's support lifecycle.

**Why it matters:** a release past end of support receives no fixes from IBM, security fixes included, and is not certified against current operating systems.

**Fix:** plan an upgrade to a release in support. Db2 12.1 is the release this plug-in certifies as primary; 11.5 is supported until 30 April 2027. IBM's Db2 Distributed end-of-support dates are the authoritative schedule.

#### Modification Pack Behind the Latest for Its Release

`ip_db2_fixpack_behind_latest` · Warning · importance Normal · folder Modification Pack Currency · parameters `MIN_MOD_115` (9), `MIN_MOD_121` (5)

**Checks:** that the server runs the latest modification pack of its release: 11.5.9 for 11.5 and 12.1.5 for 12.1 by default.

**Why it matters:** IBM builds fixes, security special builds included, only on the latest modification pack. A server on an older one must upgrade before it can take an urgent fix.

**Fix:** plan the upgrade (`installFixPack`, then `db2iupdt` and `db2updv` on each database). If your site standardises on an earlier level, change `MIN_MOD_115` or `MIN_MOD_121` for the targets that follow it.

## Related

- [Prerequisites](prerequisites.md#monitoring-role): the monitoring user and its grants
- [Alerts and templates](alerts-and-templates.md#incident-rules): the incident a score drop opens, and configuration drift, which also reports as a compliance violation
- [Upgrade notes](upgrade-notes.md#compliance-scores): the score drop, with the other steps after you upgrade from GA
- [Troubleshooting](troubleshooting.md#compliance): a standard that shows nothing
- [Trial setup](trial.md): associating the standards during an evaluation
- [What's new](whats-new.md#update-24-1-2): everything else in this release
