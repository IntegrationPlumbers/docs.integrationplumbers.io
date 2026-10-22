---
title: Moving from the beta to GA
nav_order: 5.7
---

# Moving from the Open Beta to GA

**For Open Beta users.** The Open Beta has ended and the plug-in is generally available. This page says what moving to the released plug-in involves, and how to do it, so read it before you plan the move.

| | |
|---|---|
| Product | Integration Plumbers IBM Db2 Plug-in for Oracle Enterprise Manager |
| Released plug-in | Plug-in `ip.em.xdb2`. GA was **24.1.1.0.0** for Enterprise Manager 24ai and **13.5.2.0.0** for Enterprise Manager 13.5, released 2026-10-12. The current release is **24.1.2.0.0** / **13.5.3.0.0**, released 2026-10-23: install that one |
| Open Beta | Plug-in `ip.em.xdbb`, versions `24.1.9.N.0` / `13.5.9.N.0`; the last drop was `24.1.9.9.0` / `13.5.9.4.0`. **There is no further beta drop** |
| How to move | A clean install of GA, side by side with the beta, then undeploy the beta (section 3) |
| Reference | [IBM Db2 plug-in User Guide](index.md): the authoritative description of what the released plug-in does |

## 1. What GA means for a beta install

GA is a **different plug-in** from the beta, by design. It has its own identity, its own target type and its own licence keys:

| | Open Beta | GA |
|---|---|---|
| Plug-in ID | `ip.em.xdbb` | `ip.em.xdb2` |
| Target type | `ip_db2_database_beta`, shown as *IBM DB2 Database (Beta)* | `ip_db2_database`, shown as *IBM Db2 Database* (and, from 24.1.2.0.0, `ip_db2_instance`, *IBM Db2 Instance*) |
| Versions | `24.1.9.N.0` / `13.5.9.N.0` | `24.1.1.0.0` / `13.5.2.0.0` (GA), now `24.1.2.0.0` / `13.5.3.0.0` |
| Licence keys | Issued for `ip.em.xdbb` | Issued for `ip.em.xdb2` |

- **Beta to GA is a clean install, not an upgrade.** Deploying GA does not replace or upgrade the beta. Nothing the beta created in your Management Repository carries into GA: targets, metric history, incidents, thresholds you tuned and credentials all stay with the beta.
- **The two run side by side.** Both plug-ins can be deployed to the same OMS and the same agent at once, so you can bring GA up next to the beta, check it, and only then retire the beta.
- **A beta licence key does not unlock GA**, and a GA key does not unlock the beta. A key issued for the other identity reads `Invalid Signature`. Request GA keys from your Integration Plumbers contact.
- **The beta build stays a pre-release build.** It was provided for evaluation, not for production monitoring or compliance-of-record. Run production monitoring on GA.

## 2. What does not carry over, and how to redo it

| Item | What happens | What to do on GA |
|---|---|---|
| **Targets** | Beta targets stay beta targets | Add each database again as an `ip_db2_database` target (section 3) |
| **Credentials** | Enterprise Manager never exports credentials | Set them again: the monitoring password, and the truststore and OMS credentials where you use them |
| **Licence keys** | A beta key is rejected by GA as `Invalid Signature` | Enter a GA key on each GA target |
| **Thresholds** | Settings on beta targets stay on them | GA ships its own curated defaults ([Alerts and thresholds](alerts-and-templates.md#default-thresholds)). Re-apply only your own changes: read them with `emcli get_threshold -target_name=<beta target> -target_type=ip_db2_database_beta`, then set them on the GA target with `emcli modify_threshold` |
| **Monitoring templates** | A template belongs to one target type | Re-create yours for `ip_db2_database`, or start from the shipped Starter, Standard or Production-critical template ([Monitoring templates](alerts-and-templates.md#monitoring-templates)). Do not apply the beta threshold starter kit to GA targets: its values already ship as defaults |
| **Metric history** | Stays with the beta targets and cannot be moved | GA collects from the moment each target is added. Keep the beta targets for as long as you need their history |
| **Incidents and events** | Stay with the beta targets | GA raises its own. Beta incidents close when their targets are removed |
| **Groups, incident rules, notifications** | These refer to beta targets or the beta target type | Add the GA targets to your groups, and point rules at `ip_db2_database` |
| **Preferred credentials and jobs** | Job credentials and job schedules are per target | Set the preferred credentials on each GA target ([Jobs](jobs-and-metric-extensions.md#credentials)) and re-create any scheduled jobs under the GA job types |
| **Compliance** | Standard associations are per target | Associate the compliance standards with the GA targets ([Compliance standards](compliance-standards.md#associate)) |
| **Driver directory** | The beta reads `<agentStateDir>/ip_plugin/xdbb/lib`; GA reads `<agentStateDir>/ip_plugin/xdb2/lib` | Nothing to do normally: the driver is bundled, so both are empty. Copy a file across only if support asked you to place one |

## 3. How to move

### 3.1 Install GA alongside the beta

Import the GA release file that matches your Enterprise Manager, deploy it to the OMS, then to every agent that monitors a beta target. The beta keeps running. [Install and upgrade](install-and-upgrade.md) has the full procedure, and how to verify the download; in brief:

```
emcli login -username=<em administrator>
emcli import_update -file="/tmp/24.1.2.0.0_ip.em.xdb2_2000_0.opar" -omslocal
emcli deploy_plugin_on_server -plugin="ip.em.xdb2:24.1.2.0.0" -dbUser=SYS -dbPassword=<repository SYS password>
emcli get_plugin_deployment_status -plugin=ip.em.xdb2       # wait for Success
emcli deploy_plugin_on_agent -plugin="ip.em.xdb2:24.1.2.0.0" -agent_names="<agent host>:<port>"
```

On Enterprise Manager 13.5, use `13.5.3.0.0_ip.em.xdb2_2000_0.opar` and `13.5.3.0.0` in place of `24.1.2.0.0` (13.5 also accepts `-sys_password=<repository SYS password>` in place of `-dbUser`/`-dbPassword`). **Always pin the `:version`** on both deploy commands.

### 3.2 Add each database as a GA target

For each beta target, add an **IBM Db2 Database** target with the same connection properties, a GA licence key in its licence credential set, and the monitoring credentials: see [Targets and properties](targets-and-properties.md). On an agent that runs on the Db2 host, the databases may already be proposed under **Auto Discovery Results** ([Target discovery](discovery.md)). A GA target may keep its beta target's name, because Enterprise Manager keys targets by name *and* type, but distinct names make the two easier to tell apart while both run.

### 3.3 Check each GA target

After a collection or two, each GA target should be **Up**, its **License** status should be `Active`, and its pages should show data. Then redo the items in section 2 that you use.

### 3.4 Retire the beta

Once you no longer need the beta's history, remove every **IBM DB2 Database (Beta)** target first, then undeploy the beta from the agents (`emcli undeploy_plugin_from_agent -plugin=ip.em.xdbb -agent_names=...`), then from the OMS (`emcli undeploy_plugin_from_server -plugin=ip.em.xdbb -dbUser=SYS -dbPassword=<repository password>`, or `-sys_password=...` on Enterprise Manager 13.5). Removing a beta target removes its metric history for good. Finish by deleting the beta's entry from Self Update, as described in [Uninstall](install-and-upgrade.md#uninstall).

## 4. What changed since the beta

Everything new since the beta is on [What's new](whats-new.md): the GA release and 24.1.2.0.0 / 13.5.3.0.0. The changes most likely to surprise a beta user:

- **The administrative job types are renamed.** The beta's `sidbb_*` job types become `ip_db2_start_instance`, `ip_db2_stop_instance`, `ip_db2_quiesce_database`, `ip_db2_unquiesce_database` and `ip_db2_kill_application`. Saved jobs and job library entries do not carry over. See [Breaking changes](whats-new.md#breaking-changes).
- **Three remote admin jobs**, Force Application, RUNSTATS on a Table and Online Backup, work on a remotely monitored target. They run as a separate admin user in the new **IBM DB2 Database Admin Credentials** set. See [Remote admin jobs](jobs-and-metric-extensions.md#remote-admin-jobs).
- **Availability reads differently.**
  - An HADR standby is **Up**, not Down, and raises no collection errors for the groups it cannot serve. See [Monitoring a standby](hadr-monitoring.md#monitoring-a-standby).
  - A database on an unsupported Db2 version or topology still reports availability. Every other group reads `DISABLED` in CollectorStatus, with the reason.
  - A wrong password, a missing privilege, a TLS problem, or a database quiesced against the monitoring user is now a *metric collection error*, not "target is down".
- **New alert and collection defaults.** More conditions alert out of the box, and the lock, HADR status and backup groups collect more often. See [Changed defaults](whats-new.md#changed-defaults).
- **Licensing.** The key is a credential (the *IBM DB2 Plug-in Licence Monitoring Credentials* set), not a target property. `Exceeded Limit` no longer stops collection, an expired key has a 14-day grace period, and a licence gate leaves **CollectorStatus** and **readiness_summary** running, alongside License, Response and Version. See [Licensing](targets-and-properties.md#licensing).
- **DataFiles is retired**, replaced by Table_Overflow, keyed per table.
- **The console is redesigned.** The beta's Home, Analysis and Performance pages become seventeen pages, from Overview to Monitoring Readiness. **Kill** is on the root blocker's row on **Locks** and on each row of **Sessions**, and asks for confirmation. See [Monitoring pages](monitoring-pages.md).
- **SQL text is collected.** Top Statements shows each statement's SQL text, which is stored in the repository and can contain literal values. Read [Statement text and your data](whats-new.md#statement-text-privacy) before you roll GA out.

- **Several lock and session metric groups are renamed** (for example `Lock_Waits` is `Longest_Lock_Waits`). Re-create thresholds against the names the released plug-in uses. See [Upgrade notes](upgrade-notes.md#renamed-groups).

The GA known issue (Top Statements losing its SQL text after one failed lookup) is fixed in 24.1.2.0.0 / 13.5.3.0.0.

## 5. Where to report {#reporting}

Send questions about the move, and anything you find on GA, to **helpdesk@integrationplumbers.io** (every email opens a ticket you can follow in the [customer portal](https://integrationplumbers.zohodesk.com/portal/en/home)), or open the ticket there directly. Include the plug-in version (`emcli list_plugins_on_server`), your Enterprise Manager version (24ai or 13.5), the Db2 version (11.5 or 12.1), the metric group or page involved, and any deploy log, agent log or collection-error text.

## Related

- [What's new](whats-new.md): everything since the beta
- [Install and upgrade](install-and-upgrade.md): install the released plug-in and verify the download
- [Targets and properties](targets-and-properties.md): add targets and enter licence keys
- [Changelog](changelog.md): every release, and the beta history
