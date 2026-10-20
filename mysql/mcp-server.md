---
title: EM MCP Server
nav_order: 12
---

# The plug-in and the Enterprise Manager MCP Server

Enterprise Manager 24ai Release Update 12 (24.1.0.12) and later ship an MCP server, a read-only interface that lets an AI assistant ask Enterprise Manager about targets, metrics and incidents. This chapter says what such an assistant sees for the MySQL target types, how to connect one, what to ask, and where the boundary is. Oracle's Enterprise Manager documentation for Release Update 12 covers enabling the server and connecting a client; this chapter does not repeat it.

## 11.1 What an AI client sees

The MCP server reads the Enterprise Manager repository, so an assistant sees the MySQL targets the way the console does, through the same data. For the three target types (`ip_mysql_database`, `ip_mysql_cluster` and `ip_mysql_clusterset`) that is:

- Every target, with its type, status and availability history. The target list is type-blind: a MySQL target appears beside Oracle Database and host targets.
- Every metric group of a target, with each column's label and unit, and the latest collected row or rows. Units project by name, for example `days`, `hours`, `seconds`, `microseconds`, `bytes`, `%` and `per second`. A plain count, a 0/1 flag, a coded value and a string all project as `n/a`, which is why each such column's label says what it counts or what its values mean (see [6.3](metrics-reference.md#63-naming-conventions)).
- Keyed groups row by row: the members of a cluster, the clusters of a ClusterSet, the statements of a ranking, each with its key columns.
- Open incidents and events on a target, with the alert message. The message is the only place a threshold reaches an assistant (see [11.5](#115-thresholds-reach-an-assistant-only-through-the-alert-message)).

What an assistant does not see is the metric description text: Enterprise Manager's MCP server passes labels, units and values and leaves the authored descriptions in the console (see the note in [6.3](metrics-reference.md#63-naming-conventions)). The plug-in's labels, unit declarations and explicit "never", "unknown" and "not applicable" flags were written with that in mind, so a column reads correctly from its label alone.

## 11.2 Connecting an assistant

The MCP server is part of the OMS. Enable it and connect your assistant as Oracle's documentation describes; the plug-in needs nothing extra, and nothing is installed on the agent or on MySQL. The assistant acts as the Enterprise Manager user whose credentials it holds, so it sees exactly the targets that user can see. Give it a user with view privileges on the MySQL targets and nothing more; the server has no write path the plug-in uses.

One session setting to know about: the server tells every client, at session start, that "databases" means Oracle Database target types. In our validation runs, capable assistants read the estate, noticed that the MySQL targets were databases too, and said so before answering. A more constrained assistant may follow the instruction and report no databases. If yours does, add one line to your own prompt:

```
Database targets in this estate include the MySQL types ip_mysql_database,
ip_mysql_cluster and ip_mysql_clusterset. Treat them as databases.
```

## 11.3 Six questions and what to expect

These are the kinds of question the plug-in's data answers well, with the shape of answer our validation runs produced. Target names are examples.

1. **"List every database target, grouped by type."** Every MySQL Database, MySQL InnoDB Cluster and MySQL InnoDB ClusterSet target, typed correctly, with its status. Expect the assistant to say whether it counted the cluster and ClusterSet targets as databases.
2. **"Which databases in this estate are unhealthy?"** The targets that are Down, plus those with open CRITICAL incidents, each with the metric behind it, for example a backup older than its threshold or a ClusterSet that is not ready for DR promotion.
3. **"Assess the health of the orders database."** Availability, the InnoDB buffer pool hit rate and its page counts, statement and wait activity, replication state, the backup age and the license state, read from the latest rows, with a confidence per finding. A first collection reports its rates as 0 over MCP; an assistant that cross-checks the cumulative counters notices this.
4. **"Assess the health of the orders cluster."** The member count, each member's role and state, and the Group Replication summary, with the applier and certifier queues and consensus timing from the per-member rows.
5. **"What is the most recent incident, and what would you do?"** The incident, the metric and value behind it, the threshold quoted from the alert message, and a recommendation. In our runs the assistant distinguished a backup that had stopped running from one that was failing, and declined to clear the incident by raising the threshold.
6. **"Is the ClusterSet ready for a DR promotion?"** The DR Promotion Ready flag, the health status and source, and the fallback reason when MySQL Shell could not assess it. A ClusterSet whose health reads Unknown is reported as not assessed, not as broken.

## 11.4 The security boundary

What was tested, on Enterprise Manager 24ai 24.1.0.12:

- The MCP server reads the Enterprise Manager repository. Every answer above came from repository views, under the privileges of the Enterprise Manager user the assistant connected as.
- The server's SQL tool runs against the repository. Its option to run a statement against a monitored target rejected every request before a credential was consulted, so on 24.1.0.12 no route from the MCP server to a monitored MySQL server could be exercised. The plug-in grants none: the monitoring credentials stay in Enterprise Manager's credential store and are never returned by the server.
- Nothing in the plug-in listens for the MCP server, and the agent is not involved. Removing the MCP server, or the assistant's Enterprise Manager user, removes the access entirely.

Treat the assistant's Enterprise Manager user like any other console user: it sees what that user can see, including the statement text the sessions collection stores where that collection is enabled (see [2.4](prerequisites.md#24-the-monitoring-user)).

## 11.5 Thresholds reach an assistant only through the alert message

The MCP server does not expose a metric's threshold settings: a request for them returns an error on 24.1.0.12, and the metric group metadata carries no threshold field. An assistant learns that a threshold exists only when it fires, from the incident's message. The plug-in's default threshold messages are therefore written for a reader with no console in front of them: each names the metric, the value and the limit it crossed.

Two consequences for how you tune thresholds ([chapter 7](alerts-and-thresholds.md#alert-thresholds)). A threshold you change in the console is invisible to an assistant until it fires, so an assistant assessing a target reasons from the shipped defaults it has seen in messages, not from your settings. And the confidence an assistant places in a finding tracks the thresholds you keep: a limit set to a value that is normal for your estate produces incidents an assistant will treat as real.

## 11.6 What it cannot do

- Run a statement on a MySQL server, or read anything the collections did not collect.
- Change a threshold, acknowledge an incident, or run a job. The server the plug-in was validated against is read-only for these target types.
- Read metric descriptions or threshold settings, as 11.1 and 11.5 describe.
- Name a cluster member in an all-string keyed group. Every keyed group in this release carries at least one numeric column so its rows project; report a group whose rows do not.

Validated 2026-09-29 and 2026-09-30 on Enterprise Manager 24ai Release Update 12 (24.1.0.12) with a pre-release build of this plug-in; the GA release keeps the same labels, units and flag rules. Enterprise Manager 13.5 has no MCP server.
