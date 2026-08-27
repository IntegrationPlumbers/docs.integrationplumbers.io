---
title: Early access
nav_order: 3
---

# Early access

This release is pre-release software. This page is what that means in practice.

**In this page:** What Early Access is · What has been verified · What has not · Not for production · Reporting what you find · Moving to the general release

## What Early Access is {#what-it-is}

The same build the team works with, made available before general release so you can evaluate it and tell us what is wrong with it while there is still time to change it.

It carries its own identity in Enterprise Manager — a distinct plug-in and target type, with "(Beta)" in the display name — so a beta deployment is obvious in your console, your configuration tables and your compliance results, and can never be confused with a general release.

## What has been verified {#verified}

- **Deployment and collection** on Enterprise Manager 24ai and 13.5, on both Linux and Windows agents, monitoring remotely and locally.
- **The SQL Server version matrix**, 2016 through 2025, collected against on live instances of each.
- **Availability groups**, including failover readiness against a live group.
- **The least-privilege credential model** — every documented grant is exercised.
- **Metadata validation** — the plug-in passes Oracle's full validation chain with no violations.

## What has not {#not-verified}

- **Scale.** The largest instance tested holds a normal developer database count. Behaviour and collection overhead at a hundred or more databases on one instance is not yet measured.
- **Windows Integrated Authentication.** Supported on a Windows agent, but not exercised in our lab. SQL authentication is fully exercised on both platforms.
- **Upgrade between builds.** There is no supported in-place upgrade during Early Access; see below.

## Not for production {#not-production}

Do not run this on production equipment. It has no production support commitment, no service level, and no upgrade path to the general release.

That last point is deliberate rather than an oversight. Because the Early Access build carries its own plug-in identity and target type, the general release cannot adopt its targets — so moving from Early Access to the general release is a **clean install**, by design. Nothing the beta creates in your Enterprise Manager repository survives into the general release, which is exactly the property that keeps pre-release data out of a production estate.

Deploy it where a clean install later costs you nothing.

## Reporting what you find {#reporting}

The most useful reports include your Enterprise Manager release, your SQL Server version and edition, the host operating system, what you did, and what happened. [Troubleshooting](troubleshooting.html#reporting) has the full list.

Especially valuable during Early Access:

- Deploy or import failures, with the exact error
- Metric values that look wrong, or that differ from what your previous tooling reported — these are high priority
- Instances hosting many databases, with any observation about collection overhead
- Console pages that render incorrectly, with your browser and version

Route it through the Early Access channel provided with your build. Support is best-effort during the beta.

## Moving to the general release {#to-ga}

Install the general release alongside, add your targets to it, and remove the Early Access plug-in when you are satisfied. Because the two are separate plug-ins, they can coexist while you transition.

Anything you tuned on a beta target — thresholds, credentials, schedules — has to be set again on the general-release target. Worth keeping a note of your changes as you make them.
