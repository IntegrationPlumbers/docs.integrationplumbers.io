---
title: Trial setup
nav_order: 3
---

# Trial setup

If you want to know whether the PostgreSQL plug-in earns a place in your Enterprise Manager before you buy it, a trial gives you the whole product: every page, advisor, and metric in this guide, running on your own OMS against your own PostgreSQL instances. Request a key through the form below, enter it on each target, then work the guided checklist further down this page. It exercises every advisor in about a week.

> **Prerequisites for this page**
> - Enterprise Manager 13.5.0.0.0 or later, or 24ai 24.1.0.0.0 or later, with an agent that can reach the instances you want to evaluate — see [Enterprise Manager and agents](prerequisites.md#enterprise-manager).
> - PostgreSQL 14 to 18 and a monitoring role on each instance — see [The monitoring role](prerequisites.md#monitoring-role).
> - **Agent Host Credentials** set under Preferred Credentials for every target you add. Several pages in the checklist below read their data through Enterprise Manager jobs and report "Unable to run job. Verify Preferred Credentials are set for this target." without them — see [Preferred Credentials](prerequisites.md#preferred-credentials).

**Where to find it:** the request form is at [integrationplumbers.io/postgresql-plugin/trial](https://integrationplumbers.io/postgresql-plugin/trial). The key you are sent goes into the **Plugin License** property on each target, under **Target Setup ▸ Monitoring Configuration**, and the target's **License Info** page confirms it.

**In this page:** Request a trial · Your trial key · Install · Guided evaluation · Send us your findings · Buying

## Request a trial

Request the key before you install anything. A valid license key is required to monitor a target — it is a target property — and adding a target validates the target count against your license.

Fill in the form at [integrationplumbers.io/postgresql-plugin/trial](https://integrationplumbers.io/postgresql-plugin/trial). Have four answers ready.

| What we ask for | Why it matters |
|---|---|
| Your Enterprise Manager version, 13.5 or 24ai | It decides which build you receive, 24.1.1.0.0 for 24ai or 13.5.15.0.0 for 13.5. Both carry the same features, so this changes nothing about what you can evaluate; it also tells us which console screens to point you at. |
| Your PostgreSQL versions, 14 to 18 | Versions outside that range are not supported. See [Supported versions and platforms](prerequisites.md#supported-versions). |
| How many instances you want to monitor | The key carries an instance count, and that count is what the **Instances** column on **License Info** reports back to you. |
| Whether your agents are local or remote | Both are supported. Every read travels over one JDBC connection, including reading the server log for captured plans, so a remote agent collects the same metric data as a local agent, apart from three local-only capabilities: the [Logs](monitoring-pages.md#logs) page, the Kill Idle Connections job, and the collection throttle. Knowing which you run lets us check the network path with you up front. |

While you wait for the key, work through the [Prerequisites checklist](prerequisites.md#checklist) on the instance you plan to evaluate. The minimum list gets every monitoring page populating; the full advisory list adds `auto_explain` and one superuser grant, which is what **Plan Analysis** and **Plan Drift Advisor** need. The plug-in never installs an extension and never grants a privilege to itself, so those two items are yours to do whether you trial or buy.

## Your trial key

A trial runs for 30 days. Request a key through the [trial page](https://integrationplumbers.io/postgresql-plugin/trial) or by emailing [sales@integrationplumbers.io](mailto:sales@integrationplumbers.io); Integration Plumbers issues the key once the request has been processed. Download details for the OPAR and the monitoring template files, including SHA-256 checksums, come with your trial enrollment — see [Download](install-and-upgrade.md#download) if you need access.

### Enter the key

1. Open the PostgreSQL Database target and go to **Target Setup ▸ Monitoring Configuration**.
2. Enter the key in the **Plugin License** property. See [Database target properties](targets-and-properties.md#database-properties) for the property in context.
3. Save the properties.
4. Repeat for each target. License keys are entered per target, so a second instance added later needs the same key entered again.

### Verify it

Open **License Info**, at the bottom of the target's navigation tree. It shows the license record the plug-in recognizes for that target.

| Column | Shows |
|---|---|
| Customer | The name the license is issued to |
| Type | The license type |
| Status | Current license status |
| Expiration | Expiration date |
| Instances | Number of instances the license covers |
| Days Remaining | Days left before expiration |

If the table reads "No licenses configured", the key has not been saved on the target you are looking at. Go back to **Monitoring Configuration** and check the **Plugin License** property. See [Monitoring pages](monitoring-pages.md) for the rest of the target's pages.

Licensing is per monitored instance: one key carries an instance count, and the **Instances** column is where you read it. For pricing, use the self-serve quote tool on [integrationplumbers.io](https://integrationplumbers.io).

**Days Remaining** is the number to keep an eye on during the evaluation. Give yourself enough of it to reach the week-1 steps below, which need history depth that only accumulates with time. When it reaches 0 the key has expired: the target's pages show an expiry banner and collections stop.

## Install

Installing for a trial is the same work as installing for a purchase: prepare PostgreSQL, import the OPAR, deploy it to the OMS and to the agents, add a target, enter the key, set Preferred Credentials, then check readiness.

Follow [Getting started](getting-started.md). It walks the whole path in order and links the detail for each step, so nothing is repeated here.

## Guided evaluation

The checklist is ordered by what the product can show you on each day, not by importance. Day 1 covers everything that works from the first collection. Day 2 to 3 needs plans in the archive. Week 1 needs history depth in the agent-local store. Work the rows in order and you will have touched every advisor by the end of the week.

### Day 1

Everything here needs only the target added and the key in place.

| What to do | What you should see | Page |
|---|---|---|
| Open **Monitoring Readiness** and read the seven panels top to bottom. | Every panel chip reads **OK**, apart from two expected exceptions: panels whose only unmet items are tagged optional cap at **Attention** and are fine to leave, and **Plan Capture (auto_explain)** reads **Not functional** until you work the next two rows. On a new target **Historical Store** reads `not created yet`, which is expected. | [Monitoring Readiness](monitoring-readiness.md) |
| On the **Plan Capture (auto_explain)** panel, click **Configure auto_explain**, read the preview, and click **Apply**. | An inline confirmation under the heading "The following will be applied to this database (new sessions only, no restart):", then the status line "Applied. Re-checking live settings… (new sessions pick the settings up)". The page re-probes once and the button disappears when everything settable is green. | [Configure auto_explain](monitoring-readiness.md#configure-auto-explain) |
| Copy the `GRANT pg_read_server_files TO "<monitoring role>";` statement from the **Server log read grant** item, run it as a superuser, and reload the page. | The item stops reading `not granted` and the **Plan Capture (auto_explain)** panel leaves **Not functional**. This is the one item the plug-in will never apply for you. | [Monitoring Readiness](monitoring-readiness.md) |
| Open **Index Advisor** and read the KPI band. | **Detections by Category** tiles for Missing, Unused, Invalid, HOT-inhibiting, and Consolidation. The Unused tile also carries the summed on-disk size of every unused index, for example `3 / 2.4 GB`. | [Index Advisor](index-advisor.md) |
| Click any **Recommended SQL**, **Suggested**, or **Action SQL** cell. | The statement opens in a dialog headed "Query Text" with a **Copy to Clipboard** button that reads "Copied" for a second and a half. There is no apply action anywhere on the page: you run the SQL yourself, in your own tooling. | [Index Advisor](index-advisor.md) |
| Open **Vacuum Advisor** and read the **XID Consumption** line. | One live line of the form "Cluster-wide max XID age: 148,332,190 — oldest database: template0 · ~6.9% of the 2B wraparound limit". Wraparound is cluster-scoped, so the oldest database is very often a template database, and that is normal. | [Vacuum Advisor](vacuum-advisor.md) |
| Read **Tables · Vacuum Recommendations**, then the matching row in **Per-Table Vacuum Recommendations (Full Detail)**, then click the **Recommendation** cell. | The slim list carries Table, Dead Ratio, Last Autovacuum, Severity, and Recommendation; the full-detail row adds the evidence, including **Trigger Point**, **Eff. Scale Factor**, and **Reloptions**. The cell opens tuning SQL such as `ALTER TABLE public.orders SET (autovacuum_vacuum_scale_factor=0.02);` in a copy dialog. | [Vacuum Advisor](vacuum-advisor.md) |
| Open **Realtime ▸ Vacuum xmin Horizon** and set **Auto Refresh** to 15, 30, or 60 seconds. | A live holder list with **Is Horizon**, **xmin Age**, and **Suggested Action**. The row where **Is Horizon** is 1 is the blocker; the rest are queued behind it. An empty table is the healthy state, not a collection failure. | [Vacuum Advisor](vacuum-advisor.md) |

### Day 2 to 3

These steps need captured plans, so give the database a day of real traffic above the capture threshold first.

| What to do | What you should see | Page |
|---|---|---|
| Open **Plan Analysis** and read the **Overview** tiles. | **Captured plans**, **High-cost plans**, and **Capture threshold**, the last read from the database rather than from anything you set. Before anything has been harvested the list reads "No captured plans yet. Enable auto_explain (log_min_duration >= 0, log_format = json, log_analyze = on) to populate this panel." — an instruction, not an error. | [Plan Analysis](plan-analysis.md) |
| Expand a row in **Historical Query Insights**. | The stored plan body renders as a tree, with each node's type, cost, estimated versus actual rows, and actual time. Under a **Recommendations** heading below it, one card per detected insight, each naming the pathology, the evidence, and the change to make. A clean capture reads "No insights detected for this capture." | [Plan Analysis](plan-analysis.md) |
| Set a value in **High-cost threshold (optimizer Total Cost)** and click **Save threshold**. | "High-cost threshold saved.", and the KPI tiles reload straight away. Nothing is re-harvested: the threshold reclassifies the plans already stored, in cost units rather than milliseconds. | [Plan Analysis](plan-analysis.md) |
| Open **Plan Drift Advisor** and read **Problematic Queries**. | One row per query and database that scored worse than OK, with a **Severity** badge of Cost Drift or Plan Changed. When nothing is drifting the list reads "No problematic queries found."; when your filter hides it, "No queries match the current severity filter." | [Plan Drift Advisor](plan-drift-advisor.md) |
| Select a query, go to **Baseline Management**, select the row carrying the **Current** badge, fill in **Label** and **Note**, and click **Accept**. | The shape joins the accepted set and the query stops being off-baseline. In **Plan Comparison** above, the right-hand tree stops reading "No accepted baseline for this query yet. Accept one in Baseline Management below." and renders the baseline plan beside the current one. | [Plan Drift Advisor](plan-drift-advisor.md) |
| Scroll to **Audit Trail**. | A row for the action you just took, with **When**, **Action**, **Actor**, **Reason**, and **Label**. The actor is the Enterprise Manager user who clicked, which is how you answer who certified a plan and why. Before any action the table reads "No audit events." | [Plan Drift Advisor](plan-drift-advisor.md) |
| In **Fix Workbench: Test a Rewrite**, replace bound-parameter placeholders such as `$1` with real values, edit the statement into the rewrite you want to test, and click **Run Explain**. | "Running EXPLAIN…" while the job runs, then the resulting plan tree to compare against the Current and Baseline trees above. This is the only place in the product that executes a statement against your database (the Index Advisor's HypoPG simulation plans a synthetic lookup with `EXPLAIN (FORMAT JSON)` and executes nothing). The run is capped at 30 seconds and happens inside a transaction that is rolled back. | [Plan Drift Advisor](plan-drift-advisor.md) |
| Return to **Vacuum Advisor** and look at **Autovacuum runs · 24h** in the Vacuum Health band. | A number in place of the day-1 "—", once two daily snapshots exist to delta. Hover it for the two snapshots the delta was computed over. On a busy database, zero runs in 24 hours is itself the finding. | [Vacuum Advisor](vacuum-advisor.md) |

### Week 1

These steps need history depth, which accumulates on its own from the moment the target is monitored.

| What to do | What you should see | Page |
|---|---|---|
| Open **Workload History**, set **From** and **To** around a period you care about, and read the KPI band. | **History depth**, **Statements · window**, and **Workload vs prior window**, the last comparing this window against the equal-length window immediately before it as ▲/▼/▬ with a percentage. It reads "Accumulating" while the prior window holds no snapshots yet, and "n/a" when no explicit window is set. | [Workload History](workload-history.md) |
| Sort **Workload Detail** by the metric that moved, then click the statement row whose **Trend** matches the shape of the chart. | The **Statement Drill-down** panel opens above the list and plots that one statement's own history for the metric and window you chose. Until you click a row it reads "Select a statement row below to see that statement's own history for the chosen metric and window." Widen the window: a spike that survives is a real regression. | [Workload History](workload-history.md) |
| Import `ip_xpgs_standard` with `emcli import_template`, then apply it to a non-production target with `emcli apply_template`. Both steps are also available under **Enterprise → Monitoring → Monitoring Templates**. | The template applies its standard baseline: core health on a 15-minute schedule with loosened wraparound and connection thresholds, and the advisory metrics collected store-only on a 1-hour schedule. Findings collect; nothing pages. | [Monitoring templates](alerts-and-templates.md#templates) |
| Turn one advisory finding into an incident: either apply `ip_xpgs_production_critical`, which carries the `index_advisor` and `index_advisor_whatif` thresholds, or set a Warning threshold yourself under **Target menu → Monitoring → Metric and Collection Settings**. | When a `HIGH`-severity Index Advisor finding is collected, Enterprise Manager opens an incident exactly as it does for any other target type, routed through the notification connectors you already have bound. The alert names the category, the object, and the detail. It clears itself at the next collection after the finding resolves. | [Alerts and templates](alerts-and-templates.md#default-thresholds) |
| Open **Retention Policies** and read the windows before you decide what to keep. | Twelve history types, each with **Min retention (days)** and **Max retention (days)**, above a **Store Size Limit** section whose hint reads "0 = disabled (no size-based eviction)". Saving reports "Retention policies saved. Changes take effect at the next daily trim." | [Retention Policies page](history-store-and-retention.md#retention-policies) |

Empty is a result, not a gap. "No problematic queries found." means no query has regressed against its own recent history; once you have accepted baselines, it also means nothing is running on an uncertified plan. An empty **xmin Horizon · Holder Detail** table means nothing is pinning cleanup. An empty **HypoPG What-If Simulation** section means `hypopg` is not installed in that database, or there was nothing worth simulating. Read those states as answers, and use **Monitoring Readiness** to tell a healthy empty from a missing prerequisite.

## Send us your findings

Tell us what you found, including the parts that did not work. Evaluation feedback is how the next build gets better.

- **Email:** [helpdesk@integrationplumbers.io](mailto:helpdesk@integrationplumbers.io)
- **Self-Service Portal:** [https://integrationplumbers.zohodesk.com/portal/en/signin](https://integrationplumbers.zohodesk.com/portal/en/signin)

Include these five things, so we can reproduce what you are seeing:

- The plug-in version. Run `emcli list_plugins_on_server` and find `ip.em.xpgs` in the output.
- Your Enterprise Manager version.
- Your PostgreSQL version.
- The page or metric involved.
- A screenshot of what you are seeing.

Before you write, check [Troubleshooting](troubleshooting.md). An empty advisor page, a KPI stuck on "—", and a job error each have a known cause and a fix there.

## Buying

Use the self-serve quote tool on [integrationplumbers.io](https://integrationplumbers.io), or email [sales@integrationplumbers.io](mailto:sales@integrationplumbers.io), to buy or to add instances to a license you already hold.

Buying changes the key, not the installation. Enter the production key in the same **Plugin License** property under **Target Setup ▸ Monitoring Configuration** on each target, then open **License Info** and check the **Type**, **Expiration**, and **Instances** columns. Nothing else moves: the targets, the thresholds, the templates you applied, and the history already accumulated in the agent-local store all stay exactly as they are.

## Related

- [Getting started](getting-started.md) — the install path a trial follows, step by step
- [Prerequisites](prerequisites.md#checklist) — the checklist to work through while you wait for the key
- [Monitoring Readiness](monitoring-readiness.md) — the day-1 page that tells you what is and is not ready
- [Monitoring pages](monitoring-pages.md) — **License Info** and every other page on the target
- [Alerts and templates](alerts-and-templates.md#templates) — the templates applied in the week-1 step
- [Troubleshooting](troubleshooting.md) — support contacts, and the common empty states explained
