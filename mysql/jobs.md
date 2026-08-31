---
title: Jobs
nav_order: 9
---

# Jobs

This chapter describes the job types the plug-in adds.
**Topics:** 8.1 Run EXPLAIN
## 8.1 Run EXPLAIN
The plug-in adds one job type, **MySQL - Run Explain Plan** (`ip_mysql_run_explain`). It runs `EXPLAIN` for a statement you supply against one monitored MySQL Database target and returns the execution plan.

**The job is read-only: it asks the server for the statement's plan and does not execute the statement.**

| Item | Value |
|---|---|
| Job type | `ip_mysql_run_explain` — **MySQL - Run Explain Plan** in the job library |
| Target type | `ip_mysql_database_beta` |
| Targets per run | Exactly one |
| **Query** (`query`) | Required. The statement to explain. Substitute real values for any `?` placeholders — a digest taken from Query Analyzer is normalized and will not explain as it stands. |
| **Database Name** (`db_name`) | Optional. The schema to run the statement against. Supply it whenever the statement's object names are not fully qualified. |

**Credentials.** The job needs two, and they do different things:

- **The target's monitoring credential** — the MySQL account from [2.4](prerequisites.md#the-monitoring-user), held in the target's MySQL Database monitoring credential set. This is what connects to MySQL and asks for the plan.
- **A Host Preferred Credential on the target** — a named host credential whose run-as is the management agent's operating-system user. This is what lets the agent start the plug-in's own program on the agent host.

Set the host credential once per target, under **Setup → Security → Preferred Credentials**: select the **MySQL Database** target type, open **Manage Preferred Credentials**, and set the target's host credential set to a named credential that runs as the agent's operating-system user.

> **Note:** Without a Host Preferred Credential on the target the job fails with `Unable to get credentials for defaultHostCred`. The agent's own operating-system credential is not resolved automatically for this job type, so a named host credential is required rather than optional.

To run the job:

1. Choose **Enterprise → Job → Activity**, then **Create Job**.
2. Select **MySQL - Run Explain Plan**.
3. Name the job and add exactly one MySQL Database target.
4. On the **Parameters** tab, enter the **Query** and, where the statement needs it, the **Database Name**.
5. Check the **Credentials** tab if the target's preferred credentials are not the ones you want used.
6. Submit.

The plan comes back in the job's output: open the completed run from **Enterprise → Job → Activity**, drill into it, and open the step's output log. Both parameters are recorded with the results, so a saved job is also a record of the statement that was explained.

The Query Analyzer page ([5.1](monitoring-pages.md#mysql-database-pages)) submits the same job for you and renders what it returns as a grid in its **Explain Plan** region. That is the quicker route when you are already looking at the statement; the job library route is the one to use when you want the run recorded, scheduled or repeated.
