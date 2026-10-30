---
title: EM MCP Server
nav_order: 12.5
---

# The plug-in and the Enterprise Manager MCP Server

Enterprise Manager 24ai Release Update 12 (24.1.0.12) and later ship a Model Context Protocol (MCP) server. It gives an AI client, meaning an assistant, agent or chat tool that speaks MCP, read access to targets, metrics and incidents. This page says what such a client sees for the Db2 targets this plug-in monitors, how to connect one, what to ask, how to tell an empty metric group from a broken one, and where the boundary is. It is for administrators who connect an assistant to Enterprise Manager. Oracle's documentation covers enabling the server; this page does not repeat it.

> **Prerequisites for this page**
> - An Enterprise Manager 24ai OMS at Release Update 12 (24.1.0.12) or later. Enterprise Manager 13.5 has no MCP server, so this page does not apply to the 13.5 edition of the plug-in.
> - Db2 targets that have collected at least once. A client reads only what has reached the repository.

**Where to find it:** the MCP endpoint of your OMS, `https://<oms-host>:<console-https-port>/em/api/mcp`

**In this page:** What an AI client sees · Connecting an assistant · Sample questions · Reading CollectorStatus · Thresholds and the alert message · The security boundary · What it cannot do

Everything here was validated against **IBM Db2 Database** targets (`ip_db2_database`) in a clean-room evaluation: independent runs, each given one question and no other context. Claims stay within what that evaluation exercised. The **IBM Db2 Instance** target (`ip_db2_instance`), new in this release, was not part of it. The instance target carries the same `CollectorStatus` group (see [Reading CollectorStatus](#collectorstatus)); nothing else on this page is claimed for it.

## What an AI client sees {#what-an-ai-client-sees}

**Targets.** A client finds the Db2 database targets and does not skip them. The MCP server's own guidance text talks mainly about Oracle target types, but in the evaluation an unhealthy Db2 database with an open incident was reported beside everything else.

**Metric groups.** `ListTargetMetricGroups` lists every performance metric group in the [metrics reference](metrics-reference.md): availability, performance, storage, locking, HADR, backup and Top SQL, the same data the console shows. The exception is **Diag_Log_File_Monitoring**. It exists only when the agent runs on the Db2 server (the `local` property is 1), as in the console; see [Diagnostic log monitoring](metrics-reference.md#diag-log).

**Configuration groups are listed separately.** The daily [configuration inventory](metrics-reference.md#configuration) does not appear in `ListTargetMetricGroups` at all. Enterprise Manager serves it through a separate pair of tools: `ListConfigMetricGroups` lists the configuration groups by display name, and `GetConfigurationMetricData` reads them. The listing was verified. Reading configuration values back this way was not tested, and this page makes no claim about it.

**Columns: label, unit and value.** The MCP server passes each column's label, its unit and the value. Every label in this plug-in states its unit, its value set or its encoding, for example `HADR Role (PRIMARY | STANDBY | STANDARD)` or `Auto-Resize Enabled (0/1, 1 = enabled)`. Time, size and percentage columns also carry a real unit (`seconds`, `bytes`, `%`). A plain count shows its unit as `n/a`, because Enterprise Manager has no unit for a count, so its label ends in `(count)` instead.

**Descriptions stay in the console.** Every metric group has an authored description on the console's All Metrics page. The MCP server returns it neither on the group definition nor on an alert event. A client understands a group from its column labels, units, thresholds and alert messages, which is why those carry the meaning.

**Data is what has reached the repository.** There is no on-demand collection over MCP. A client reads the same uploaded data the console charts read. Right after a target is added, every group reads empty until its first collection completes, from 5 minutes to 24 hours depending on the group ([collection intervals](alerts-and-templates.md#collection-intervals)). That is expected, not a fault.

**Empty is not always the same empty.** `HADR_Status` and `HADR_Readiness` return no rows on a database that is not in an HADR pair, because the feature does not apply. [Reading CollectorStatus](#collectorstatus) is how a client tells that apart from "not collected yet" and from "collection is failing".

## Connecting an assistant {#connecting}

The endpoint is part of Enterprise Manager, not something this plug-in adds. Nothing is installed on the agent or on Db2. On an OMS at 24ai Release Update 12 or later it is at:

```
https://<oms-host>:<console-https-port>/em/api/mcp
```

It takes JSON-RPC over HTTP POST, with HTTP Basic authentication as an Enterprise Manager user, and supports MCP protocol versions `2025-06-18` and `2025-11-25`. For the connection and configuration reference, see the MCP server topic in Oracle's Enterprise Manager 24ai Administrator's Guide:

```
https://docs.oracle.com/pls/topic/lookup?ctx=en/enterprise-manager/cloud-control/enterprise-manager-cloud-control/24.1&id=GUID-45163229-8876-4201-AAD3-FE63C13C06D0
```

**Use a dedicated, least-privilege Enterprise Manager user.** Give it View on the targets the client should see, and nothing more. A client acts with whatever that user may do, and it can read the target properties of every target it can see (see [The security boundary](#security-boundary)). Do not connect it as SYSMAN or another Super Administrator, and do not grant the user any privilege you would not want an AI client to use on your behalf.

## Sample questions and what to expect {#sample-questions}

Each question below was given to a separate run with no other context about the plug-in. The confidence is the one each run reported. Target names are placeholders.

| Question | The kind of answer to expect |
| :--- | :--- |
| "Which databases in this estate are unhealthy?" | The Db2 targets are found and not skipped, and an unhealthy Db2 database with an open incident is reported beside everything else. High confidence. |
| "List every database target, grouped by target type." | A complete list, with the Db2 target type, its display name and its description. High confidence: enumeration is what the MCP surface answers best. |
| "Assess the health of &lt;a Db2 target&gt;." | On a new target, an answer from availability and incidents only ("up, no open incidents, too new to say more"), because the groups read empty until their first collection. Once data has been collected, a fuller answer that cites specific columns and any threshold breach. Medium to Medium-High confidence. An empty HADR group no longer leaves the client guessing: one read of `CollectorStatus` says why. |
| "What is the most recent incident, and what would you do?" | The metric group, column and value quoted from the incident record, the severity classified correctly, and a plausible next step. For a tablespace utilization breach, for example: check the reading is still current, then extend or resize the tablespace. High confidence on the incident facts; lower on remediation details the client cannot check from MCP data. |

## Reading CollectorStatus: why a metric group is empty {#collectorstatus}

Over MCP, a group with nothing to say and a group that is broken look identical: `GetLatestData` returns `{"items": [], "count": 0}` for both. The `CollectorStatus` group tells them apart. `ListTargetMetricGroups` lists it like any other group. It collects every 5 minutes, even while the target is down, and it is never empty itself. Both target types carry it, with the same columns and the same alert.

**How to read it.** Call `GetLatestData` on `CollectorStatus`. You get one row per metric group, keyed by `MetricGroup`:

| Column | What it holds |
| :--- | :--- |
| `MetricGroup` | The metric group the row is about, spelled exactly as `ListTargetMetricGroups` spells it |
| `Status` | One word from the closed set below |
| `Reason` | A plain-language explanation, up to 512 characters. For `COLLECTION_ERROR` it carries the SQLSTATE and the driver's message |
| `LastAttempt` | Always empty. Read `LastAttemptEpoch` |
| `RowsReturned` | How many rows the last attempt wrote: a real count, never a coded value |
| `LastDurationMs` | How long the last attempt took, in milliseconds |
| `ConsecutiveErrors` | Attempts in a row that ended in `COLLECTION_ERROR`, the last one included |
| `LastAttemptEpoch` | When the agent last tried, in seconds since 1970-01-01 UTC. Empty means never |

`LastAttempt` once held the time as text. Enterprise Manager keeps every change of a text column as history, and that value changed on every collection, so the time now travels as the number `LastAttemptEpoch`. To read it as a date in SQL against the repository, use `DATE '1970-01-01' + value / 86400` (UTC).

**On an upgraded OMS, restart the OMS after deploying.** Until you do, `LastAttempt` is already blank and `LastAttemptEpoch` is still empty, so no group shows an attempt time and a stalled collector looks like a working one. See [Restart the OMS](upgrade-notes.md#restart-oms).

**The vocabulary.** Six words, and no others. They are the same in every Integration Plumbers plug-in, so a client that learns them once can read any of them.

| `Status` | What it means | What to do |
| :--- | :--- | :--- |
| `OK` | The group collected and returned at least one row. | Nothing. |
| `NOT_CONFIGURED` | The feature the group measures is not set up on this database, for example HADR on a standalone database. "Nothing here" is the correct answer until a DBA changes something. | Nothing; report it as the answer. |
| `NOT_COLLECTED_YET` | The group has never completed a first collection on this target, or the history it needs has not built up yet. | Say so, wait, and read again. |
| `NO_DATA` | The collector ran, the feature is set up, and the query returned no rows this cycle, for example no lock waits right now. | Nothing; report it as the answer. |
| `COLLECTION_ERROR` | The collection was attempted and failed. | Act, and quote `Reason`. |
| `DISABLED` | The group is switched off for this target by design: the `local` gate on `Diag_Log_File_Monitoring`, the licence gate when the licence is not active, or an unsupported Db2 version or topology. | Nothing about the database. The fix is a monitoring or licensing change. |

**The legend row.** Every collection carries a row whose `MetricGroup` is `_Vocabulary`. Its `Reason` spells out the whole set: `Closed status set: OK | NOT_CONFIGURED | NOT_COLLECTED_YET | NO_DATA | COLLECTION_ERROR | DISABLED`. It exists because Enterprise Manager truncates a column label at 64 characters, so the `Status` label cannot hold all six words. Rows over MCP are ordered by the key column, so find the legend by its key, not by its position.

**One alert, on one word.** The shipped condition goes Critical when `Status` matches `COLLECTION_ERROR` on two consecutive collections, and the alert carries the group name and the reason. The other five words never alert: each means the absence of rows is the right answer.

**`Diag_Log_File_Monitoring` is the special case.** When the agent is not on the Db2 server, that group is removed from the target entirely. Reading it over MCP returns a "resource does not exist or caller has no privilege" error, not an empty result, which reads like a permissions problem or a typo. Its `CollectorStatus` row is the only place that says `DISABLED` and why.

**A collection skipped on purpose.** If the agent administrator has turned on the optional [collection throttle](prerequisites.md#collection-throttle), a group whose last interval was skipped because the agent host was busy keeps its `Status`. Its `Reason` starts `Collection paused by the agent-load collection throttle` and names the threshold reached. Report it as "paused on a busy agent host", not as a database fault. It clears at the group's next collection.

**`LastAttemptEpoch` is the agent's clock.** Metric data reaches the repository, and so `GetLatestData`, only after the agent uploads it. In that window a group can read `OK` here with a recent attempt time while `GetLatestData` on the group still returns nothing, and an alert can already have fired on data the client cannot see yet. That is upload latency, and it closes within a collection cycle or two.

## Thresholds and the alert message {#thresholds}

Thresholds are the strongest signal a client gets. A group with a shipped alert condition tells the client what "bad" looks like without guessing. Examples on the database target:

| Metric | Shipped condition |
| :--- | :--- |
| Tablespace used of maximum (`Tablespace_Forecast : PctUsed`) | Warning above 80 %, Critical above 90 % |
| Catalog and package cache hit ratios (`Cache`) | Warning below 80 %, Critical below 70 % |
| Availability (`Response`) | Critical when the target is down |
| `CollectorStatus` | Critical on `COLLECTION_ERROR` |

The full list is in [Default thresholds](alerts-and-templates.md#default-thresholds), and the [monitoring templates](alerts-and-templates.md#monitoring-templates) add a tighter production set and three more alerts you can enable.

When a threshold fires, the incident message names the metric, the value and the limit it crossed. In the evaluation, a client asked about the most recent incident quoted the metric group, column and value straight from the incident record. A threshold you tune for your estate changes what a client treats as a real problem: a limit set at a value that is normal for you produces incidents a client will report as faults.

## The security boundary {#security-boundary}

What was tested, on Enterprise Manager 24ai Release Update 12:

- **Target properties are readable** by any MCP client with access to the target, including the target's host, port and database name.
- **Monitoring credentials are not readable** when they were set through the monitoring credential set, as [Add a target with EM CLI](targets-and-properties.md#add-target-emcli) describes. In the one case tested where a username and password were passed inline on `add_target`, both were stored as ordinary target properties and were readable over MCP. Always set credentials through the credential set. If a target may have been added the inline way, check its properties and re-add the credentials through the set if `DB2Username` or `DB2Password` is listed.
- **The licence key** is a credential from database target metadata 4.8, held in the licence credential set, so `ListTargetProperties` cannot read it. A key still in the old **Plugin Licence Key** property, on a target upgraded from an earlier release, is a target property and stays readable until you move it ([Licence key in a credential set](upgrade-notes.md#licence-credential)).
- **The SQL tool.** The MCP server offers a SQL tool that queries the Enterprise Manager repository, within the privileges of the connecting user. It was not tested against a Db2 database, and this page makes no claim about what it can reach there.

Treat the client's Enterprise Manager user like any other console user. It sees what that user can see, including the statement text that the SQL Statement Text and Top Queries groups store ([Statement text and your data](whats-new.md#statement-text-privacy)).

## What it cannot do {#limits}

- **Read the group descriptions.** They exist on the console's All Metrics page, but the MCP server does not return them.
- **Query your Db2 database directly.** The SQL tool reaches the Enterprise Manager repository. It was not tested against a Db2 target.
- **Tell from an empty HADR group alone** whether there is no standby or the group has not collected yet. `HADR_Status` and `HADR_Readiness` look the same in both cases; one read of `CollectorStatus` answers it.
- **Report a status for a collector that has stopped altogether.** If the agent or the target is down, `CollectorStatus` goes stale rather than turning red, and `LastAttemptEpoch` is what shows it. For that case, use the target's availability and status history.
- **See metric data before the first collection completes** on a new target, however the question is asked.
- **Read configuration values,** as far as anything was tested: the configuration groups are listed, but reading them back was not verified.

## Related

- [Metrics reference](metrics-reference.md): every metric group and column a client can read.
- [CollectorStatus](metrics-reference.md#collectorstatus): the group's entry in the metrics reference.
- [Default thresholds](alerts-and-templates.md#default-thresholds): the shipped alert conditions a client reasons from.
- [Add a target with EM CLI](targets-and-properties.md#add-target-emcli): setting credentials through the credential set.
- [Licensing](targets-and-properties.md#licensing): the licence credential set.
- [Instance targets](targets-and-properties.md#instance-targets): the IBM Db2 Instance target.
- [An empty metric group](troubleshooting.md#empty-group): the same question, from the console.
- [AI troubleshooting guide](https://docs.integrationplumbers.io/db2/ai/troubleshooting.md): a self-contained file to load into an assistant when a Monitoring Readiness check fails.
