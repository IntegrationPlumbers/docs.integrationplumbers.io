---
title: AI clients and the MCP Server
nav_order: 26
---

# AI clients and the MCP Server

From Enterprise Manager 24ai RU12 (24.1.0.12), Enterprise Manager ships its own Model Context Protocol (MCP) server. It gives an AI client, meaning an assistant, agent or chat tool that speaks MCP, read access to the Enterprise Manager estate, including the SQL Server targets this plug-in monitors. Nothing in the plug-in has to be enabled for it: everything the plug-in collects is exposed the same way Oracle's own target types are.

This page describes what such a client sees, how to connect one, what to expect from it and where the limits are. It rests on a clean-room evaluation against three SQL Server targets on an RU12 system: six independent AI agents, each given one question, no documentation and no access beyond the MCP server. Nothing here claims more than that evaluation tested.

**In this page:** What a client sees · How to connect · Sample questions · What it cannot do

## What a client sees {#what-a-client-sees}

**Targets.** `ListTargets` returns the SQL Server targets with their type and ids, and a client asked about "databases" finds them. The MCP server's own guidance text describes databases in Oracle terms, but in the evaluation every agent asked about unhealthy databases found the SQL Server targets alongside the others.

**Metric groups.** `ListTargetMetricGroups` returns every collected metric group in the [metrics reference](metrics-reference.md). The three configuration groups (SQL Server Instance, Database Settings, AlwaysOn Databases) are not in that list. Enterprise Manager serves configuration data through a separate pair of tools, `ListConfigMetricGroups` and `GetConfigurationMetricData`; see [What it cannot do](#cannot) for what reading them returns on RU12. A count of the groups in `ListTargetMetricGroups` therefore comes up three short of the metric definitions, and nothing is missing.

**Columns: label, unit and value, nothing else.** The MCP server hands a client each column's display label, its unit and the value. A metric group's description is not passed on, so the plug-in's labels state what their values mean: what 1 means on a flag, the codes of a coded column, the window of an interval column, and how "never" is shown. Time, size and percentage columns also carry a real unit (`seconds`, `KB`, `KB per second`, `hours`, `days` and so on). A plain count or a code shows as `n/a`, because Enterprise Manager has no unit for it, and the label carries the meaning instead.

**Thresholds reach a client through incidents, not metadata.** The plug-in ships [default thresholds](alerts-and-thresholds.md), but the MCP server has no tool that returns a threshold, and a metric group's definition carries no threshold field. A client learns what "bad" looks like for a column when a threshold has fired: the incident text names the metric, the value and the breach. In the evaluation, three of six agents named missing backups as the estate's real problem without being asked about backups.

**Data is what has reached the repository.** A client reads the same uploaded data the console charts read; there is no on-demand collection. A new target reads empty until each group's first collection has run and been uploaded: a minute for availability, up to 24 hours for the daily groups. A new target can read Up for several minutes before its first metric data can be queried.

## How to connect {#connect}

The endpoint is part of Enterprise Manager, not something this plug-in adds. On an RU12 or later Management Server it is at:

```
https://<oms-host>:<console-https-port>/em/api/mcp
```

It takes JSON-RPC over HTTP POST with HTTP Basic authentication as an Enterprise Manager user. An unauthenticated POST answering HTTP 401 (rather than 404) shows the endpoint is there. For the connection and configuration reference, see Oracle's Enterprise Manager 24ai Administrator's Guide topic on the MCP server:

```
https://docs.oracle.com/pls/topic/lookup?ctx=en/enterprise-manager/cloud-control/enterprise-manager-cloud-control/24.1&id=GUID-45163229-8876-4201-AAD3-FE63C13C06D0
```

Connect as a dedicated Enterprise Manager user with View on the targets the client should see and nothing more. Target properties are visible to any client that can see the target (see [What it cannot do](#cannot)), and an AI client acts with whatever the connecting user may do, so do not connect it as SYSMAN or a Super Administrator.

Two things a client author trips on first:

- `ListMetricTimeSeries` rejects a timestamp without milliseconds: `2026-09-17T16:36:08Z` is refused as an invalid parameter, `2026-09-17T16:36:08.000Z` works.
- A time series arrives as `items[].datapoints`, a list of `[timestamp, value]` pairs. Reading a value field off the item itself gives nothing, which looks like an empty result.

## Sample questions {#sample-questions}

Each question below was given to a separate agent with no other context. The confidence is the one each agent reported.

| Question | The kind of answer to expect |
| :--- | :--- |
| "Which databases in this estate are unhealthy?" | Finds every SQL Server target and names backup posture as the problem they share. High confidence. |
| "List every database target, grouped by target type." | A complete list, confirmed two ways. High confidence; enumeration is what the MCP surface answers best. |
| "Assess the health of &lt;target&gt;." | A detailed assessment citing specific columns: load, memory, sessions, the backup gap, a database in FULL recovery that has never been backed up. Agents cross-checked counters against each other, for example deriving instance uptime three independent ways. Mostly High confidence, with the columns they could not interpret named rather than guessed at. |
| "Assess the health of &lt;a SQL Server 2016 or 2017 target&gt;." | The same quality on the oldest supported versions. |
| "Are the databases on &lt;target&gt; being backed up adequately? If not, what would you do?" | A correct diagnosis with the right nuance, separating databases that have never been backed up from ones that are merely stale, and a remediation that included the plug-in's own [Back up database job](jobs.md), found without being told the plug-in provides it. High confidence. |
| "What is the most recent incident, and what would you do?" | Answers from whatever incident is newest in the whole estate, which in the evaluation was an Enterprise Manager infrastructure incident rather than a SQL Server one. Scope the question to SQL Server targets when that is what you mean. |

What made the answers good: the shipped thresholds firing into readable incidents, units on time and size columns, and labels that state their encodings. Where an agent's confidence dropped, the cause was a column whose meaning lived somewhere the client could not see.

## What it cannot do {#cannot}

- **Read configuration data on RU12.** `GetConfigurationMetricData` returned Unauthorized even as SYSMAN, for this plug-in's three configuration groups and equally for Oracle's own Enterprise Manager repository target, while `ListConfigMetricGroups` listed them. So SQL Server version, edition, product level and collation are not reachable this way on that release. The same values are in the console and through EM CLI.
- **See thresholds as metadata.** A client sees a threshold only once it has fired.
- **See metric group descriptions.** They are shown in the console only.
- **Get a sorted top-N.** The top-query and query-plan groups hold the right 500 rows for their measure, but Enterprise Manager stores metric rows unordered. A client has to read the whole set and sort it.
- **Tell an unknown number from a zero by the value alone.** A blank numeric value can reach a client as 0. Where that matters the plug-in publishes a companion column, such as CPU Counters Available beside the CPU columns and Commit Position Known beside the availability-group recovery point, and the label of the value says what blank means. Read the companion before trusting a 0.
- **Tell from an empty group alone why it is empty.** A group whose feature is not set up (an availability group on a standalone instance, for example), one that has not collected yet and one whose collection is failing all read the same.
- **Point at the SQL Server host.** `GetTarget.hostName` is the host of the Enterprise Manager agent that monitors the target, which for a remotely monitored instance is not the machine SQL Server runs on. The target's Host property and the HostInfo group describe the SQL Server host.
- **Query SQL Server directly.** The MCP server's SQL tool reached the Enterprise Manager repository under the connecting user's privileges in the evaluation. Whether it can reach a monitored SQL Server instance was not tested, and this guide makes no claim either way.
- **Keep target properties private.** The evaluation read target properties back over MCP, so treat every one, the License Key included, as visible to any client that can see the target. The monitoring username and password are [credential properties](credentials.md#applying), held in Enterprise Manager's credential store rather than as target properties; whether a client can read them was not tested.

## Related

- [Metrics reference](metrics-reference.md)
- [Alerts and thresholds](alerts-and-thresholds.md)
- [Credentials](credentials.md)
