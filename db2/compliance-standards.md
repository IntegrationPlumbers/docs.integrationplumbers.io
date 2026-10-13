---
title: Compliance standards
nav_order: 9
---

# Compliance standards

This release ships three compliance standards with 17 rules for Db2 databases. They are evaluated in the Enterprise Manager repository on data the plug-in already collects — the daily configuration snapshot — under the same least-privilege `SQLADM` monitoring user everything else in this guide uses, with one narrow extra grant only on a hardened installation. Deploying the plug-in installs the content; it does not evaluate anything until you associate a standard with your targets.

> **Prerequisites for this page**
> - The plug-in deployed to the OMS — deploying it installs the compliance content automatically, with no separate registration step.
> - At least one target's configuration collection has run once, for the standards to have anything to evaluate — see [Let a configuration collection run](#let-a-configuration-collection-run).
> - `SELECT` on `SYSCAT.AUDITPOLICIES` / `SYSCAT.AUDITUSE`, only if your installation has revoked `PUBLIC` access to those views — see [The monitoring role](prerequisites.md#monitoring-role).

**Where to find it:** Enterprise → Compliance → Library, and Enterprise → Compliance → Results.

**In this page:** What ships · Associate a standard with targets · Let a configuration collection run · Read results · Rules by standard

## What ships

| Standard | Rules | What it checks |
| :--- | :---: | :--- |
| **IBM Db2 Database Configuration Best Practices** | 10 | Diagnostic logging (logging level, notify level, diagnostic path), recovery (circular logging, backup protection, resync interval), memory (monitor heap, sort-heap threshold), and **network and platform security**: the instance offers TLS (`DB2COMM` includes `SSL`), and on Windows, Db2 extended security is not turned off (`DB2_EXTSECURITY` is not `NO`). |
| **IBM Db2 Database Audit Posture** | 5 | An audit policy exists, is assigned, and covers the expected categories, read from `SYSCAT.AUDITPOLICIES` and `SYSCAT.AUDITUSE`; with auditing on, audit records are written asynchronously (`AUDIT_BUF_SZ` above 0); and SYSADM authority belongs to a named `SYSADM_GROUP` rather than the operating system default. |
| **IBM Db2 Database Version Lifecycle** | 2 | The Db2 release is not past its IBM end-of-support date, and the server runs the **latest modification pack** of its release. IBM builds fixes only on the latest mod pack. The minimums are rule parameters, `MIN_MOD_115` (default 9) and `MIN_MOD_121` (default 5), so a site that standardises on an earlier level can change them. |

All 17 rules target `ip_db2_database`, and every one is referenced by exactly one of the three standards — there is nothing shipped that can never evaluate.

## Associate a standard with targets {#associate}

**Nothing evaluates until you do this** — an installed-but-unassociated standard is the usual reason the compliance dashboard shows an empty Db2 bar.

In the console:

1. Go to **Enterprise → Compliance → Library**, open the **Compliance Standards** tab.
2. Select a standard, then **Associate Targets**, and add your `ip_db2_database` targets.
3. Repeat for the other two standards.

With `emcli`, scriptable across as many targets as you like — once per standard, with the version the Library shows:

```
emcli associate_cs_targets -name="ip_db2_config_best_practices" -version=2 -author=SYSMAN \
      -target_list="<target1>,<target2>"
emcli associate_cs_targets -name="ip_db2_version_lifecycle" -version=1 -author=SYSMAN \
      -target_list="<target1>,<target2>"
emcli associate_cs_targets -name="ip_db2_audit_posture" -version=1 -author=SYSMAN \
      -target_list="<target1>,<target2>"
```

Add `-force` to evaluate again at once, for example after a configuration change.

## Let a configuration collection run {#let-a-configuration-collection-run}

The rules read this plug-in's own configuration data through the repository's auto-generated views, which stay empty until the underlying configuration metrics have collected at least once — a 24-hour cadence. A newly associated standard on a brand-new target legitimately shows nothing until that first upload lands; that is not a broken check.

## Read results

Open **Enterprise → Compliance → Results**. Each standard reports Targets Evaluated, Violations (by severity), and a Score. Version Lifecycle scoring 100% simply means every monitored database is on an in-support release at its latest modification pack (by default 11.5.9 or 12.1.5) — that is the correct, expected result on a current estate, not a sign the check did nothing. A database one or more mod packs behind is flagged even while its release is still in support.

A freshly associated, unhardened install will often show findings on Configuration Best Practices and Audit Posture on the first pass — most environments have not tuned every one of the ten configuration checks, and many have not defined an audit policy at all. Treat the first result as a baseline to work from, not a defect in the plug-in.

## Rules by standard

**IBM Db2 Database Configuration Best Practices** (10) — `diaglevel`, `notifylevel`, `diagpath`, circular logging, backup protection, `resync interval`, `mon_heap`, `sheapthres`, `DB2COMM` without `SSL`, and Windows extended security turned off.

**IBM Db2 Database Audit Posture** (5) — no audit policy defined, an audit policy defined but not assigned, an assigned policy that does not cover the expected categories, audit records written synchronously, and no `SYSADM_GROUP` set.

**IBM Db2 Database Version Lifecycle** (2) — the monitored Db2 version is past its IBM end-of-support date, and the modification pack is behind the latest for its release.

## Related

- [Prerequisites](prerequisites.md#monitoring-role) — the audit-posture catalog-view grant, and when you need it
- [Trial setup](trial.md#guided-evaluation) — associating standards as part of the guided evaluation
- [What's new](whats-new.md) — where this fits among everything else new in this release
