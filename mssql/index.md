---
title: SQL Server Plug-in
nav_order: 0
---

# Microsoft SQL Server Plug-in

## Integration Plumbers

### Oracle Enterprise Manager Plug-in for Microsoft SQL Server User Guide

*Early Access (beta) · `24.1.9.N.0` for Enterprise Manager 24ai · `13.5.9.N.0` for Enterprise Manager 13.5*
*August 2026*

This release ships as two plug-in builds with the same features: one for Enterprise Manager 24ai and one for Enterprise Manager 13.5. Enterprise Manager decides whether it will accept a plug-in from the toolkit it was built with, not from its version number, so the two are not interchangeable — install the build that matches your Enterprise Manager. Everything in this guide applies to both.

<details>
<summary>Legal Notice</summary>

Information in this document is subject to change without notice. Complying with all applicable copyright laws is the responsibility of the user. No part of this document may be reproduced or transmitted in any form without the express written permission of Integration Plumbers.

© 2026 Integration Plumbers. All rights reserved.

Microsoft, SQL Server and Windows are trademarks of the Microsoft group of companies. Oracle and Enterprise Manager are trademarks of Oracle Corporation and/or its affiliates.

</details>

## What this plug-in does

It monitors Microsoft SQL Server from Oracle Enterprise Manager: availability, configuration, performance, queries, deadlocks, indexes, space and AlwaysOn availability groups — with console pages, alert thresholds, compliance rules and jobs that act on what you find.

One plug-in and one target type cover every supported version and both agent platforms. There is no separate build per SQL Server release, and no separate story for Windows.

## Where to start

| If you want to | Go to |
| :--- | :--- |
| See whether your estate is ready | [Prerequisites](prerequisites.html) |
| Install it | [Install and upgrade](install-and-upgrade.html) |
| Add your first instance | [Targets and properties](targets-and-properties.html) |
| Understand what a page is telling you | [Monitoring pages](page-overview.html) |
| Know what changed | [What's new](whats-new.html) |
| Tune what alerts you | [Alerts and thresholds](alerts-and-thresholds.html) |
| Take part in the beta | [Early access](early-access.html) |

## Supported versions

| Component | Supported |
| :--- | :--- |
| Oracle Enterprise Manager | Cloud Control 13.5, 24ai (24.1) |
| Microsoft SQL Server | 2016, 2017, 2019, 2022, 2025 |
| Management Agent platforms | Linux x86-64, Windows x86-64 |
| SQL Server host platforms | Windows and Linux, monitored remotely or locally |

SQL Server 2016 and 2017 collect every metric family, with two families returning less detail than on 2019 and later. [Prerequisites](prerequisites.html) has the specifics.

## A note on Early Access

This is pre-release software. It is not licensed for production use, and there is no production support commitment during the beta. [Early access](early-access.html) covers what has been verified, what has not, and how to report what you find.
