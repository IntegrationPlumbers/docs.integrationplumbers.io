---
title: Compliance rules
nav_order: 21
---

# Compliance rules

The plug-in ships fourteen compliance rules. They evaluate against data already collected, so they cost nothing extra to run against the instance.

> **Prerequisites for this page**
> - The compliance standard associated with the target. See [Where results appear](#where).
> - The monitoring login. The rules evaluate against configuration the plug-in already collects, and need no additional grants.

**In this page:** The rules · Where results appear · How they evaluate · A note on xp_cmdshell

## The rules {#the-rules}

| Rule | Flags |
| :--- | :--- |
| SQL Server Version Nearing or Past End of Support | An instance on a release at or past Microsoft's end of support |
| Database AUTO_SHRINK Enabled | A database set to shrink itself automatically |
| Max Server Memory Not Configured | An instance left on the default, unbounded memory setting |
| Max Degree of Parallelism At Default | MAXDOP never set for the workload |
| Max Worker Threads Manually Overridden | A manual override of a setting best left automatic |
| CLR Integration Enabled | CLR turned on |
| xp_cmdshell Enabled | Shell execution from SQL turned on |
| File Autogrowth Set To Percentage | Percentage growth, which grows unpredictably as a file gets larger |
| Database Has Multiple Transaction Log Files | More than one log file, which gains nothing |
| Database Backup Is Stale | No recent backup |
| Full-Recovery Database Without Log Backup | Full recovery model with no log backups, so the log grows without bound |
| Index Fragmentation - Reorganize Recommended | Fragmentation past the point where a reorganise helps |
| Index Fragmentation - Rebuild Recommended | Fragmentation past the point where only a rebuild helps |
| SQL Server Agent Not Set To Automatic Start | The Agent not set to start automatically |

Each rule carries a recommendation describing what to do about it, not just what is wrong.

## Where results appear {#where}

On the target's **Compliance** → **Results** page in Enterprise Manager. Compliance results are per target, so an estate view comes from Enterprise Manager's own compliance dashboards rather than from the plug-in.

The version end-of-support rule is the one most estates should look at first — it is the rule that finds the instances nobody remembered were still running.

## How they evaluate {#how}

Rules read values from collected metrics rather than querying the instance themselves. Two consequences worth knowing:

- A rule cannot produce a result before the metric it depends on has collected. On a newly added target, configuration-derived rules stay unevaluated until the first configuration collection — up to 24 hours. See [Targets and properties](targets-and-properties.html#new-target).
- Turning off a collection turns off the rules that depend on it.

The end-of-support rule fires on SQL Server 2016 and earlier. Releases still inside their support lifecycle do not trigger it, so a clean result on a 2019 instance is a correct result rather than a rule that failed to run.

## A note on xp_cmdshell {#xp-cmdshell}

The plug-in flags `xp_cmdshell` as a finding, and it does not ask you to enable it. Its own backup and restore jobs use native T-SQL.

This is worth stating plainly because some monitoring tools require the very setting they warn you about. This one does not.

## Related

- [Monitoring pages](monitoring-pages.html#analysis) - the Analysis page, which covers adjacent ground
- [Alerts and thresholds](alerts-and-thresholds.html) - metric thresholds, which are a separate mechanism
- [Credentials](credentials.html#why-not-sysadmin) - the least-privilege position the rules assume
- [Prerequisites](prerequisites.html#supported-versions) - the versions the end-of-support rule checks against
