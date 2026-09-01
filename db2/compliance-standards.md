---
title: Compliance standards
nav_order: 9
---

# Compliance standards

This release ships three compliance standards for Db2 databases, evaluated entirely under the same least-privilege `SQLADM` monitoring user everything else in this guide uses — no extra grant needed for two of the three, and one narrow grant for the third only on a hardened installation. Deploying the plug-in installs the content; it does not evaluate anything until you associate a standard with your targets.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS — deploying it installs the compliance content automatically, with no separate registration step.
> - At least one target's configuration collection has run once, for the configuration best-practices standard to have anything to evaluate — see [Let a configuration collection run](#let-a-configuration-collection-run).
> - `SELECT` on `SYSCAT.AUDITPOLICIES` / `SYSCAT.AUDITUSE`, only if your installation has revoked `PUBLIC` access to those views — see [The monitoring role](prerequisites.md#monitoring-role).

**Where to find it:** Enterprise → Compliance → Library, and Enterprise → Compliance → Results.

**In this page:** What ships · Associate a standard with targets · Let a configuration collection run · Read results · Rules by standard

## What ships

| Standard | Rules | What it checks |
| :--- | :---: | :--- |
| **IBM Db2 Database Configuration Best Practices** | 8 | Logging level, notify level, diagnostic path, circular logging, backup protection, resync interval, monitor heap, and sort-heap threshold, drawn from the daily configuration snapshot. |
| **IBM Db2 Database Audit Posture** | 3 | Whether an audit policy is defined, whether it is assigned, and whether it covers the expected categories, read from `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE`. |
| **IBM Db2 Database Version Lifecycle** | 1 | Whether the monitored Db2 version is past its IBM end-of-support date. |

All 12 rules target `ip_db2_database_beta` and every one is referenced by exactly one of the three standards — there is nothing shipped that can never evaluate.

## Associate a standard with targets {#associate}

**Nothing evaluates until you do this** — an installed-but-unassociated standard is the usual reason the compliance dashboard shows an empty Db2 bar.

In the console:

1. Go to **Enterprise → Compliance → Library**, open the **Compliance Standards** tab.
2. Select a standard, then **Associate Targets**, and add your `ip_db2_database_beta` targets.
3. Repeat for the other two standards.

With `emcli`, scriptable across as many targets as you like:

```
emcli associate_cs_targets -name=<standard> -version=<v> -author=SYSMAN \
      -target_list=<target1>,<target2>,<target3>
```

Add `-force` on a second run to trigger evaluation immediately instead of waiting for the next scheduled pass.

## Let a configuration collection run {#let-a-configuration-collection-run}

The configuration best-practices standard's rules read this plug-in's own configuration data through the repository's auto-generated views, which stay empty until the underlying config metrics have collected at least once — a 24-hour cadence. A newly associated standard on a brand-new target legitimately shows nothing until that first upload lands; that is not a broken check.

The audit-posture and version-lifecycle standards do not depend on this snapshot and can show results sooner.

## Read results

Open **Enterprise → Compliance → Results**. Each standard reports Targets Evaluated, Violations (by severity), and a Score. Version Lifecycle scoring 100% simply means every monitored database is on an in-support release — that is the correct, expected result on a current estate, not a sign the check did nothing.

A freshly associated, unhardened install will often show findings on Configuration Best Practices and Audit Posture on the first pass — most environments have not tuned every one of the eight configuration checks, and many have not defined an audit policy at all. Treat the first result as a baseline to work from, not a defect in the plug-in.

## Rules by standard

**IBM Db2 Database Configuration Best Practices** — `diaglevel`, `notifylevel`, `diagpath`, circular logging, backup protection, `resync interval`, `mon_heap`, `sheapthres`.

**IBM Db2 Database Audit Posture** — no audit policy defined, an audit policy defined but not assigned, and an assigned policy that does not cover the expected categories.

**IBM Db2 Database Version Lifecycle** — the monitored Db2 version is past its IBM end-of-support date.

## Related

- [Prerequisites](prerequisites.md#monitoring-role) — the audit-posture catalog-view grant, and when you need it
- [Trial setup](trial.md#guided-evaluation) — associating standards as part of the guided evaluation
- [What's new](whats-new.md) — where this fits among everything else new in this release
