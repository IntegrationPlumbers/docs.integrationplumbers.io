---
title: Metrics reference
nav_order: 7.5
---

# Metrics reference

This page describes every metric group of the two target types, **IBM Db2 Database** and **IBM Db2 Instance**: its default collection interval, its key columns, what the values mean, and the alerts that ship enabled. It is for DBAs and Enterprise Manager administrators who read **All Metrics**, set thresholds, or want to know why a group is empty.

**Where to find it:** on a target's home page, the target menu → **Monitoring** → **All Metrics**, then the group by name.

**In this page:** How to read this page · Availability · DB_Monitoring · General_Info · Application_Statistics and Top_Sessions · Appl_Connection · Agent_Connection · BufferPool · Cache · Memory · SortHeap · Db_Perf and Wait_Time · Tables, indexes and I/O · Storage · Locking · HADR · DB_Backup · Recovery history and utilities · Top SQL · Configuration inventory · Diagnostic log · CollectorStatus · Monitor_Metrics · Shipped thresholds and templates · WLM · Partitioned (DPF) databases · pureScale · Other database groups · IBM Db2 Instance target

## How to read this page {#how-to-read}

The groups collect over JDBC, mostly from Db2's `MON_GET_*` table functions, and otherwise from the catalog or administrative views named in each section.

- **Intervals are defaults.** You can change any group's schedule in **Monitoring → Metric and Collection Settings**.
- **Most columns ship with thresholds Not Defined.** Each group has more columns than this page lists, and many carry a Condition with no Warning or Critical value. They are there for you to set. This page names the thresholds that ship with values, with their operator and the number of occurrences before an alert opens.
- **Labels carry their meaning.** Every numeric column has an Enterprise Manager unit, and the label states the unit, the value set or the encoding, for example `HADR Role (PRIMARY | STANDBY | STANDARD)` or `Days Since Last Backup (-1 = never backed up)`.
- **Descriptions are console-only.** Each thresholded group, and each advisor group, has a description on the All Metrics page saying what it measures and which direction is bad. Enterprise Manager's MCP server does not return descriptions, so an AI client sees the labels, units, thresholds and alert messages, which is why those carry the interpretation.

### Interval figures and ratios {#interval-semantics}

Many figures cover the interval **since the previous collection**, not the time since the database was activated. On a lifetime base, a problem that starts after a day of uptime barely moves a ratio, so an alert could never fire.

| Rule | What it means for you |
|---|---|
| Ratios are per interval | The buffer-pool hit ratios (`Db_Perf`, `BufferPool`), the catalog and package cache hit ratios, `SortHeap.sorts_overflow_ratio` and `average_lock_wait_time` (`DB_Monitoring`, `Application_Statistics`) come from the counters' change since the previous collection (15 minutes). |
| Quiet intervals read healthy | Fewer than 100 logical reads or cache lookups shows a ratio of 100. Fewer than 20 sorts shows an overflow ratio of 0. No lock waits shows an average of 0. |
| The first collection is a baseline | Interval-delta groups (Wait_Time, BufferPool_IO_Time, Index_Activity, Latch_Waits, the WLM groups, Application_Statistics) keep the previous reading in the target's cache file. The first collection after a target is added, after an upgrade, or after the agent was down for over two hours records a baseline and writes no row. |
| Restarts are detected, not misread | A database restart is read from its activation time (for Latch_Waits, the instance start time), compared as Db2 stores it, so a daylight-saving change is never mistaken for a restart and a restart never produces a negative interval. |
| Real-time views shorten intervals | A Real-time view on the Performance page runs a collection every minute, and the plug-in cannot tell those runs from scheduled ones. While one is open, stored rows can cover about a minute. `interval_sec` says how long each row covers. |

## Availability {#availability}

**Response**, interval **5 min**. Column: `Status`. **Alert:** Critical when `Status` is not 1 ("target is down"). **DetailedResponse** (5 min) reports the instance and database status in words, `db2_status` and `db_status`.

- **Up (1).** The database answered and its status is `ACTIVE`, `QUIESCE_PEND`, `QUIESCED` or `ROLLFWD`. A quiesced or roll-forward-pending database is not an outage; `db_status` shows which state it is in.
- **Down (0).** The database or instance cannot be reached: host unreachable, connection refused, a communication error (SQLSTATE class 08), or a stopped instance. Any failure the plug-in does not recognise also counts as down, so it still alerts.
- **Cannot monitor (a metric collection error, not an outage).** The database answered, but the plug-in cannot monitor it. Enterprise Manager shows a metric collection error on the target instead of opening a "target is down" incident. The error text says what to fix:
  - authentication failed, for example a wrong or expired password (SQLSTATE 28000)
  - no monitoring password is set
  - the monitoring user lacks a privilege (SQL0551N, SQLSTATE 42501)
  - the database is **quiesced** and the monitoring user has no `QUIESCE_CONNECT` authority (SQL20157N), the usual case for the [least-privilege monitoring user](prerequisites.md#monitoring-role)
  - the TLS handshake failed (truststore or server certificate)
  - the JDBC driver could not be loaded

[CollectorStatus](#collectorstatus) records the same reason.

**DetailedResponse alerts.** `db2_status` warns when it matches `QUIESCE_PEND` or `QUIESCED`. `db_status` warns on anything but `ACTIVE`.

**A database target on an HADR standby.** A standby database reports `STANDBY`, or `ACTIVE_STANDBY` with reads on standby, so `db_status` warns there. Set that one threshold to the standby's healthy value:

```
emcli modify_threshold -target_name=<standby target> -target_type=ip_db2_database \
                       -metric=DetailedResponse -column=db_status -warning_threshold=ACTIVE_STANDBY
```

## DB_Monitoring {#db-monitoring}

Database activity, interval **15 min**.

| Key columns | Unit | Meaning |
|---|---|---|
| `db_name` (key), `server_instance_name` | name | Database and instance identity |
| `dbcapacity`, `dbsize`, `space_utilization` | bytes / % | Capacity (what the non-temporary table spaces can reach: their allocation, their MAXSIZE, or their allocation plus the free space on their file systems), their used size, and size over capacity. Read live every collection; no `SYSTOOLS` table is needed |
| `appls_cur_cons`, `appls_in_db2` | count | Current and active connections |
| `average_lock_wait_time` | ms | Average lock-wait time |
| `percent_appls_waiting_on_lock` | % | Applications waiting on locks |
| `lock_timeouts_rate`, `lock_escals_rate`, `deadlocks_rate` | per sec | Lock timeout, escalation and deadlock rates |
| `static_sql_rate`, `dynamic_sql_rate`, `commit_sql_rate`, `rollback_sql_rate` | per sec | SQL throughput rates |
| `connection_utilization` | % | Connections against the coordinating-agent limit |
| `lock_list_in_use`, `locklist_bytes`, `lock_list_utilization` | bytes / % | Lock-list memory in use, the lock list's size (`LOCKLIST` × 4 KB; when `AUTOMATIC`, the size STMM has tuned it to now), and use over size |

**Shipped alerts:**

| Column | Warning | Critical | Occurrences |
|---|---|---|---|
| `average_lock_wait_time` | above 1000 ms | above 5000 ms | 3 |
| `percent_appls_waiting_on_lock` | above 50 % | above 70 % | 3 |
| `lock_timeouts_rate` | above 0.1 | above 0.5 | 3 |
| `deadlocks_rate` | above 0.05 | above 0.2 | 3 |
| `lock_escals_rate` | above 0 | above 0.01 per sec | 3 |
| `space_utilization` | above 80 % | above 90 % | 3 |
| `connection_utilization` | above 80 % | above 90 % | 3 |
| `lock_list_utilization` | above 70 % | above 85 % | 2 |

A full lock list escalates row locks to table locks, so `lock_list_utilization` warns before `lock_escals_rate` does.

## General_Info {#general-info}

Interval **15 min**. Key columns: `db2start_time`, `agents_registered`, `comm_private_mem`, `sort_heap_allocated`, `sortheap_threshold`, `db2_status` and `sortheap_utilization` (%). **Shipped alert:** `sortheap_utilization` Warning above 90, Critical above 100 (3 occurrences). The sort heap is shown on the [Memory & Sorts page](monitoring-pages.md#memory--sorts).

## Application_Statistics and Top_Sessions {#application-statistics}

Metadata 4.7 retired `AgentStatistics` and `Sessions`, which were keyed by connection, so every connection ever seen stayed a metric key for 24 months. Their stored data is deleted on the upgrade, and thresholds set on them do not move. [Upgrade notes](upgrade-notes.md#renamed-groups) lists all seven renamed groups.

### Top_Sessions {#top-sessions}

Interval **60 min**. The session list behind the [Sessions page](monitoring-pages.md#sessions): the 25 connections using the most CPU in their **current unit of work** (`LimitRows` 25 on `uow_cpu_ms`). Keyed by `session_rank` (1 = most CPU); the connection is the `application_handle` column.

- `application_handle` (the connection; the Kill Application job takes it), `uow_id`, the current unit of work, `appl_name`, `auth_id`, `client_host`.
- `session_state` in words (see the [Sessions page](monitoring-pages.md#sessions)).
- `uow_cpu_ms`, `uow_age_sec` (0 unless the unit of work is open: it has written log or holds locks, as in Oldest_Transactions), `rows_read`, `rows_modified`, `lock_wait_ms`, `locks_held`.
- The running statement: `activity_id` (0 when none), `stmt_elapsed_sec`, `stmt_hash` (the key the SQL page and Statement Detail use) and `stmt_text` (the first 2,000 characters).

It is stored hourly because its statement, statement hash and state are text columns that change between collections, and Enterprise Manager keeps every change of a text column for about a year. The page reads it live. Because the key is the rank, the group never holds more than 25 keys. The cost is at most 25 × 3 changing columns × 24 = 1,800 history rows per target a day, plus the text columns of a rank whenever another connection takes it. No thresholds ship: Oldest_Transactions and the lock groups alert on sessions.

### Application_Statistics {#application-statistics-group}

Interval **15 min**. One row per **application name** (the key), the 50 using the most CPU (`LimitRows` 50 on `cpu_time_ms`). Every figure covers the interval since the last collection (`interval_sec`). The collector keeps each connection's counters in the target's cache file, takes each connection's change and sums the changes per application, so a connection that ends never makes a figure fall.

| Columns | Meaning |
|---|---|
| `connections` | Connections of that application |
| `locks_held`, `locks_waiting` | Now |
| `lock_waits`, `lock_wait_time` (ms), `average_lock_wait_time` (ms), `lock_escals`, `lock_timeouts`, `deadlocks` | Lock activity in the interval |
| `act_time_ms`, `cpu_time_ms`, `cpu_utilization_pct` | Activity and CPU time; CPU as a % of one CPU, above 100 when the application ran on several at once |
| `total_sorts`, `total_sort_time` | Sorts |
| `rows_read`, `rows_written` and their `_rate` per second | Row traffic |
| Static, dynamic and failed SQL statements, commits and rollbacks | Each with its rate |

Conditions on the lock, rate and CPU columns ship Not Defined. The first collection after the upgrade, or after the agent was down for over two hours, is a baseline and writes nothing. The per-statement columns `AgentStatistics` had are gone: Query_Analytics (the [SQL page](monitoring-pages.md#sql)) and Top_Sessions carry them.

## Appl_Connection {#appl-connection}

Interval **15 min**. Counts of remote and local, active, and total connections: `db_name` (key), `rem_cons_in` (remote connections), `local_cons`, `rem_cons_in_exec`, `local_cons_in_exec`, `total_cons`, `appls_cur_cons`, `appls_in_db2`. No thresholds ship.

## Agent_Connection {#agent-connection}

Interval **15 min**. Agent-pool sizing and turnover: `agents_registered`, `agents_registered_top`, `maxagents`, `idle_agents`, `agents_created_empty_pool`, `coord_agents_top`, `max_coordagents`, `agents_from_pool`, `agents_assignment_rate`, `agents_creation_rate`, `creation_to_assigning_ratio`. No thresholds ship. The instance target collects this group too.

## BufferPool and BufferPool_IO_Time {#bufferpool}

**BufferPool**, interval **15 min**. One row per buffer pool (`bufferpool_name` key): `bufferpool_hit_ratio` (%), logical and physical data and index reads, asynchronous reads, read and write times (microseconds), data and index writes. Buffer-pool efficiency and I/O. Its hit-ratio Condition ships Not Defined; the database-wide ratios in [Db_Perf](#db-perf) carry the shipped alerts.

**BufferPool_IO_Time**, interval **15 min**. How long each buffer pool's physical I/O took over the interval since the previous collection, keyed by `bufferpool_name`, from `MON_GET_BUFFERPOOL`:

- `interval_sec`: the seconds the row covers, by the database clock.
- `physical_reads`: pages read from disk (data, index, XML and column-organised, regular and temporary table spaces, prefetch included). `sync_reads`: the part a request waited on, that is, less the prefetchers' asynchronous reads.
- `read_time_ms` (`POOL_READ_TIME`) and `sync_read_time_ms` (less `POOL_ASYNC_READ_TIME`).
- `avg_read_ms`: read time per page, prefetch included. Prefetch reads many pages per I/O, so this runs below the disk's latency.
- `avg_sync_read_ms`: synchronous read time per synchronous read. A synchronous read is one page and one I/O, so this is the storage latency a request sees.
- `physical_writes`, `sync_writes` (less the page cleaners' asynchronous writes: pages an agent had to write itself), `write_time_ms`, `avg_write_ms` and `avg_sync_write_ms`.

**`avg_sync_read_ms` reads 0 below 1,000 synchronous reads per 15 minutes**, so one slow read on a quiet pool cannot alert. The floor is a rate (about 1.1 reads a second), scaled to the interval the row covers: while a Real-time view is open the interval can be about a minute, and 67 slow reads in that minute still count.

Every counter is an [interval delta](#interval-semantics). **Shipped alert:** `avg_sync_read_ms` Warning above 20, Critical above 50 ms, over 2 occurrences (30 minutes). 20 ms is where common disk-latency guidance calls reads slow on any storage (spinning disks run 5 to 10 ms, SSD and SAN far less), and 50 ms is a serious stall.

`avg_read_ms`, `avg_write_ms` and `avg_sync_write_ms` ship Not Defined on purpose. The first mixes multi-page prefetches. Writes are mostly the page cleaners' background work, whose bursts are normal. A synchronous write (a dirty steal) matters more by its count than its time. You can set any of them. The existing `SQLADM` grant is enough.

## Cache {#cache}

Interval **15 min**. `catalog_cache_hit_ratio` and `package_cache_hit_ratio` (%). From metadata 4.9, also each cache's lookups and inserts (misses) per second over the interval: `cat_cache_lookups_rate`, `cat_cache_inserts_rate`, `pkg_cache_lookups_rate`, `pkg_cache_inserts_rate`.

**Shipped alerts:** each ratio fires when it drops **below** Warning 80 %, Critical 70 % (3 occurrences). The ratios are [per interval](#interval-semantics). Shown on the [Performance page](monitoring-pages.md#performance) and, with the caches' lookup, insert and overflow counts, on [Memory & Sorts](monitoring-pages.md#memory--sorts).

## Memory {#memory}

Four groups: MemMgr_Perf, Instance_Memory, Memory_Sets and FCM_Buffers. All four, and the STMM settings from the [configuration snapshot](#configuration), are shown on the [Memory & Sorts page](monitoring-pages.md#memory--sorts).

**MemMgr_Perf**, interval **15 min**. `db_name` (key), `lock_list_in_use` (lock list current value), `shr_workspace_size_top` (shared workspace maximum used), `priv_workspace_size_top` (private workspace maximum used). No thresholds ship.

**Instance_Memory**, interval **15 min**. The memory the Db2 instance uses against its limit, for this member, from `ADMIN_GET_MEM_USAGE`:

| Column | Unit | Meaning |
|---|---|---|
| `db_name` (key) | name | The monitored database |
| `instance_memory_used` | bytes | Memory the instance uses now |
| `instance_memory_limit` | bytes | The limit: `INSTANCE_MEMORY`, or the value Db2 computed for `AUTOMATIC` (75 to 95 percent of RAM, more on larger hosts) |
| `instance_memory_peak` | bytes | The most it has used since the instance started |
| `instance_memory_setting` | `AUTOMATIC` \| `FIXED` | `FIXED`: `INSTANCE_MEMORY` is set to a number, and the limit is enforced. `AUTOMATIC`: Db2 computed it, and enforces it only on editions with a licensed memory cap |
| `instance_memory_utilization` | % | Used over limit |

**Shipped alert:** `instance_memory_utilization` Warning at 90 %, Critical at 97 % (3 occurrences, so 45 minutes). At an enforced limit Db2 refuses memory allocations (`SQL0101N`, `SQL1084C`), so 90 % leaves time to act and 97 % is the edge. With `AUTOMATIC`, the self-tuning memory manager (STMM) keeps the instance under the computed limit by giving memory back. A sustained 90 % means it has nothing left to give and the host is close to its RAM. Three occurrences ride out a short spike from a large sort or a utility.

**Memory_Sets**, interval **30 min**. One row per memory set, keyed by `memory_set_type`: the instance-level `DBMS`, `FMP`, `PRIVATE` and `FCM` sets, and this database's `DATABASE` and `APPLICATION` sets (`MON_GET_MEMORY_SET`). Columns: `memory_set_scope` (`INSTANCE` or `DATABASE`), `set_size_kb`, `set_committed_kb`, `set_used_kb` and `set_used_hwm_kb` (peak), all in KB. It shows which part of the instance's memory is growing when Instance_Memory alerts. No thresholds ship. `General_Info.comm_private_mem` still reads the FCM set alone.

**FCM_Buffers**, interval **30 min**. The fast communication manager's buffers and channels, one row per member, keyed by `member`, from `MON_GET_FCM`:

- `buff_max`, `buff_total` (allocated now; auto-tuning grows it up to the maximum), `buff_free`, `buff_free_bottom` (the fewest free since the instance started).
- `buff_used_pct`: allocated less free, as a share of the maximum.
- `buff_used_peak_pct`: allocated less the fewest free, as a share of the maximum. An upper bound on the peak.
- `buff_auto_tuning` (0/1), and the same seven for channels (`ch_*`).

All members on a host share one set of buffers and channels. `buff_used_pct` and `ch_used_pct` carry Not Defined Conditions you can set.

**Why FCM is collected on a single-member database.** FCM is how the members of a partitioned (DPF) database talk to each other, and on DPF this group has one row per member. FCM also exists on one member, for messages between agents: a single-member Db2 12.1 instance with intra-partition parallelism off still reports buffers allocated and in use. So the group collects on a single member too, where it shows one row. FCM traffic between members (`MON_GET_FCM_CONNECTION_LIST`) is not collected.

No default threshold ships because a 30-minute sample of an instantaneous value misses the bursts that matter. The peak shares never come down until the instance restarts, so an alert on them would never clear.

## SortHeap {#sortheap}

Interval **15 min**. Sort and hash-join memory: total and active sorts, sort time, sort-heap pages allocated, sort overflows, hash joins, hash loops and their overflows, post-threshold sorts and joins, plus averaged rates and ratios. **Shipped alert:** `sorts_overflow_ratio` Warning above 30, Critical above 50 (3 occurrences), computed [per interval](#interval-semantics). Shown on the [Memory & Sorts page](monitoring-pages.md#memory--sorts).

## Db_Perf, Wait_Time and Latch_Waits {#db-perf}

**Db_Perf**, interval **15 min**. Database-wide I/O: logical and physical data and index reads, asynchronous reads and writes, pool read and write times, and derived read and write rates, plus the buffer-pool, data and index hit ratios (%).

**Shipped alerts** (3 occurrences each), on ratios computed [per interval](#interval-semantics):

| Column | Warning | Critical |
|---|---|---|
| `bufferpool_hit_ratio` | below 90 % | below 80 % |
| `bufferpool_data_hit_ratio` | below 90 % | below 80 % |
| `bufferpool_index_hit_ratio` | below 95 % | below 85 % |

### Wait_Time {#wait-time}

Interval **15 min**. Where request time went since the previous collection, from `MON_GET_DATABASE`. One row, keyed by `db_name`:

- `interval_sec`: the seconds the row covers, by the database clock.
- `rqst_time_ms`: request time in the interval, summed over all agents (`TOTAL_RQST_TIME`).
- `wait_time_ms`: the part of it spent waiting (`TOTAL_WAIT_TIME`; time waiting for the client's next request is not included).
- The components, in ms:
  - `lock_wait_ms` (`LOCK_WAIT_TIME`)
  - `pool_read_wait_ms`: synchronous buffer-pool reads, `POOL_READ_TIME` less `POOL_ASYNC_READ_TIME`. At database level Db2 counts the prefetchers' reads in `POOL_READ_TIME`, and no request waits on those.
  - `log_disk_wait_ms` (`LOG_DISK_WAIT_TIME`)
  - `direct_io_wait_ms` (`DIRECT_READ_TIME` + `DIRECT_WRITE_TIME`, mostly LOBs)
  - `other_wait_ms`: the rest of the wait time (latches, network, audit, log buffer and so on), never below 0.
- The same as shares of request time: `wait_time_pct`, and `lock_wait_pct`, `pool_read_wait_pct`, `log_disk_wait_pct`, `direct_io_wait_pct` and `other_wait_pct`, which add up to `wait_time_pct`.

**How the interval works.** Every value is an [interval delta](#interval-semantics). Two more cases start a new baseline (no row for that collection, and CollectorStatus reads `NOT_COLLECTED_YET`):

- **An HADR takeover or a client reroute.** The target is then answered by another database activation, started before the stored reading, often days before. That is not a restart, so the plug-in does not publish the other server's counters since its own activation as one interval.
- **A partition that stops or comes back on a partitioned (DPF) database.** While a partition is down, Db2 answers with only the partitions that are up, so the totals lose or regain that partition's whole share. This applies to Wait_Time and to `Query_Analytics`. The next collection over the same partitions is an ordinary interval.

While a Real-time view is open the stored rows cover shorter intervals; the shares are unaffected.

**Near-idle databases read 0.** While the database spends less than 10 ms per second of the interval on requests, the shares read 0 (9 s of request time over the 15-minute schedule, 600 ms over a one-minute window). On a near-idle database one slow request would otherwise read as most of the time spent waiting. The ms columns still carry what was measured.

**Components never outgrow the total.** The four named components come from different Db2 monitor element families and can disagree slightly. If they add up to more than the wait total, they are fitted inside it in the order lock, buffer pool read, log disk, direct I/O.

**With `MON_REQ_METRICS` at `NONE`** Db2 does not count request time at all. Every column reads 0, the shares read 0, and Wait_Time itself gives no sign that anything is missing. The signal is [Monitor_Metrics](#monitor-metrics), whose `metrics_off` warns when the switch is off. To check by hand, `db2 get db cfg for <database> | grep -i MON_REQ_METRICS` must show `BASE` or `EXTENDED`.

**Shipped alerts:** `wait_time_pct` Warning above 60, Critical above 80 %, and `lock_wait_pct` Warning above 20, Critical above 40 %, both over 2 occurrences (30 minutes). When `lock_wait_pct` alerts, [Longest_Lock_Waits](#locking) and the [Locks page](monitoring-pages.md#locks) show who is blocking whom. The existing `SQLADM` grant is enough.

### Latch_Waits {#latch-waits}

Interval **15 min**. The 20 latches with the most **extended** wait time since the previous collection, keyed by `latch_name`, from `MON_GET_EXTENDED_LATCH_WAIT`. An extended wait is one in which the requester gave up the CPU rather than spinning: contention. Columns: `interval_sec`, `latch_waits`, `latch_wait_time_ms` and `avg_latch_wait_ms` (per wait).

- The counters are member-level, for the whole instance rather than one database. The plug-in reads a restart from the instance start time, and a counter that goes backwards as that latch's reset.
- Interval deltas as for Wait_Time: the first collection records a baseline, and an interval with no extended latch wait writes no row.
- No thresholds ship: latch names are Db2 internals (`SQLO_LT_...`), and how much latch waiting is normal depends on concurrency.

Latch waits are part of Wait_Time's `other_wait_ms`. When `wait_time_pct` alerts with most of it in `other_wait_pct`, this group names the latch. Where auditing is on, the audit buffer latch (`SQLO_LT_sqlexAuditBuffers__bufferLatch`) can lead the list, which points at the audit facility rather than at the SQL. The existing `SQLADM` grant is enough. The instance target collects this group too.

## Tables, indexes and I/O {#table-io}

Log I/O, direct I/O, and the per-table and per-index groups.

**LogIO**, interval **15 min**. Transaction-log reads and writes and LSN-gap cleaners, counted since the database was activated. From metadata 4.9 also `log_reads_rate` and `log_writes_rate`, log pages per second over the interval, which the [Performance page](monitoring-pages.md#performance) charts.

**NonBufferedIO**, interval **15 min**. Average direct (non-buffered) read and write rates.

**Table_Overflow**, interval **2 hr**. Per-table overflow accesses and page reorganisations, both counted since database activation: `table_schema` and `table_name` (keys), `table_type`, `page_reorgs`, `overflow_accesses`. One row per table, summed over data partitions; temporary tables are excluded. The 100 tables with the most overflow accesses are kept. High `overflow_accesses` means rows have outgrown their page and the table needs a `REORG`.

`DataFiles` is retired (metadata 2.9) and replaced by Table_Overflow. It keyed on the `page_reorgs` counter, so every reorg created a new row identity. It is no longer collected, Enterprise Manager deletes its stored data on the upgrade, and thresholds set on it do not carry over.

### Table_Maintenance {#table-maintenance}

Interval **6 hr**. Tables that need maintenance, worst first, up to 100, keyed by `table_schema` and `table_name`. Empty when nothing needs attention. Db2's own schemas (`SYSIBM`, `SYSCAT`, `SYSSTAT`, `SYSFUN`, `SYSPROC`, `SYSIBMADM`, `SYSTOOLS`, `SYSIBMINTERNAL`, `SYSIBMTS`, `SYSPUBLIC` and `NULLID`) are left out. A user schema whose name begins with `SYS`, such as PeopleSoft's `SYSADM`, is included.

**Stale statistics** means old *and* changed: at least 10 % of the rows modified since the last `RUNSTATS` (`rows_modified`, `modified_pct`), or any change to a table never analysed. `stats_stale_days` is then the age of the statistics (since creation if there are none), else 0. Neither half alone is enough: a static table's old statistics are still right, and a busy table analysed today is not stale. `VOLATILE` tables are never stale: Db2 leaves them out of automatic statistics on purpose.

`rows_modified` is Db2's in-memory count since the table was first used after the database was activated. It starts again from 0 whenever the database deactivates and after every RUNSTATS, automatic ones included. A database that is not explicitly activated deactivates when its last connection ends. In practice this flags tables that automatic statistics is not keeping up with, on a database that stays active.

**Reorg candidates** use REORGCHK's table formulas on the catalog statistics:

- `overflow_pct`: overflow rows as a share of rows; 0 for tables under 1,000 rows.
- `page_fill_pct`: pages holding rows as a share of allocated pages. Under 80 % recommends a reorg for tables over 32 pages, but not for MDC or ITC tables, whose empty pages are pre-allocated in blocks.
- `reclaimable_bytes`: an estimate of the space a reorg would free.
- `reorg_recommended`: YES when either formula fires. These are only as current as the table's last statistics.

Also `stats_collected`, `stats_time`, `stats_age_days`, `card` (-1 = never collected), `npages` and `fpages`.

**Shipped alerts** (1 occurrence): `stats_stale_days` Warning above 7, Critical above 30 days; `overflow_pct` Warning above 5 %, Critical above 20 %.

### Invalid_Objects {#invalid-objects}

Interval **1 hr**. One row: `invalid_packages` (VALID `N`, needing a rebind), `inoperative_packages` (VALID `X`, needing an explicit `REBIND`), `invalid_objects` (views, routines, triggers and the rest, from `SYSCAT.INVALIDOBJECTS`), their total `invalid_count`, and an `example_object`.

**Shipped alert:** `invalid_count` Critical above 0 (1 occurrence). With `AUTO_REVAL` at its default (`DEFERRED`), Db2 revalidates many invalid objects and rebinds `N` packages on their next use, so the alert can clear without anyone acting. `db2 "CALL SYSPROC.ADMIN_REVALIDATE_DB_OBJECTS()"` and `db2rbind <db> -l <log> all` fix the rest.

### Index_Activity {#index-activity}

Interval **30 min**. The 50 user indexes scanned most since the previous collection, keyed by `index_schema` and `index_name`, from `MON_GET_INDEX` (summed over members and data partitions) joined to `SYSCAT.INDEXES` for the index name.

| Column | Meaning |
|---|---|
| `table_schema`, `table_name` | The indexed table |
| `interval_sec` | The seconds the row covers |
| `index_scans`, `index_only_scans`, `index_jump_scans` | Scans; index-only scans are answered from the index without reading the table |
| `index_l_reads`, `index_p_reads` | Logical and physical reads, in pages |
| `page_splits` | Root, intermediate and leaf node splits; many splits suggest more `PCTFREE` |
| `index_leaf_pages` | Leaf pages now |

Interval deltas as for [Wait_Time](#wait-time): the first collection records a baseline, and only indexes with activity in the interval are listed. Catalog indexes (in Db2's own eleven schemas, as for Table_Maintenance) and indexes on declared temporary tables are left out. No thresholds ship.

**The 2,000-index window.** The plug-in remembers up to 2,000 indexes between collections, chosen by **scans since the database was activated**. An index outside that set is not reported until it has been seen twice, so it can never show its whole lifetime as one interval. On a database with more than 2,000 touched user indexes this favours long-lived busy indexes: an index that turns hot after a long quiet life is missed until its total scans climb into the top 2,000, or the database restarts. Below 2,000 touched indexes there is no bias.

### Unused_Indexes {#unused-indexes}

Interval **24 hr**. Regular, non-unique indexes on user tables and MQTs that no DML statement has scanned for **90 days**, largest first, up to 100, keyed by `index_schema` and `index_name`.

| Column | Meaning |
|---|---|
| `table_schema`, `table_name` | The indexed table |
| `index_columns` | The key columns in key order, INCLUDE columns left out; past 16 the list ends `,+N more` |
| `last_used` | `YYYY-MM-DD`, or `never` |
| `days_unused` | Days since `last_used`, or since the index was created if it was never used |
| `index_leaf_pages` | From the last `RUNSTATS`; -1 without statistics |

It reads `SYSCAT.INDEXES.LASTUSED`, which survives database restarts. Db2 updates it at most once a day, and **never for reads on an HADR standby**. An index used only by reporting queries on a readable standby shows as unused here, so check what runs on the standby before dropping anything.

Left out on purpose:

- Primary-key and unique indexes, which enforce a constraint whether scanned or not.
- **Foreign-key indexes**, whose leading key columns are exactly the columns of a foreign key on the table (in any order). Their `LASTUSED` moves only when a referential-integrity check runs, and dropping one turns every parent delete into a scan of the child table.
- Clustering, block, dimension, XML, text and other special indexes.

An unused index still costs space, `RUNSTATS` and `REORG` time, and work on every insert, update and delete of its table. An index used only by a yearly job shows here too. Empty when every index is in use. `days_unused` carries a Not Defined Condition you can set; nothing ships, because an unused index is a review item, not an incident.

## Storage {#storage}

Log space, log archiving, table spaces and the file systems under them.

### Log_Storage {#log-storage}

Interval **30 min**. Columns:

- `total_log_used` and `total_log_available`, in **bytes**, as `MON_GET_TRANSACTION_LOG` reports them.
- `sec_logs_allocated`: the count of secondary log files.
- `space_utilization` (%).
- `oldest_xact_holder`: the application handle holding the oldest transaction, which pins the active log; -1 when none.
- `oldest_xact_age_sec`: how long that transaction has been open.

**Shipped alerts:** `space_utilization` Warning above 75, Critical above 85 (3 occurrences); `sec_logs_allocated` Warning above 0. When the log is filling, `oldest_xact_holder` says which connection to look at, and [Oldest_Transactions](#locking) shows it in full.

Shown on the [Transaction Log page](monitoring-pages.md#transaction-log) as Transaction Log, with the holder of the oldest transaction (`None` when nothing pins the log), and as the Log Space Used and Secondary Log Files Allocated trends.

### Log_Archive {#log-archive}

Interval **15 min**. Is log archiving working, and keeping up? One row, from the archiver's own state in `MON_GET_TRANSACTION_LOG` (what `db2pd -logs` shows as *Method 1 Archive Status*):

| Column | Meaning |
|---|---|
| `archive_status` | `OK`; `FAILED` when the last archive attempt of `LOGARCHMETH1` or `LOGARCHMETH2` failed; `OFF` when no archive method is set (circular logging or `LOGRETAIN`); `STANDBY` on an HADR standby. Db2 retries a failed archive by itself, so `FAILED` stays until an attempt succeeds |
| `archive_method` | `LOGARCHMETH1`, then `LOGARCHMETH2` when it is set too, for example `DISK:/db2/archive/`. `UNKNOWN` when the configuration could not be read but the archiver reports a status for that method, so it is in use |
| `current_active_log` | The log file being written (`S0000123.LOG` is 123) |
| `oldest_unarchived_log` | The oldest closed log file not yet in the archive (-1 when not archiving) |
| `archive_log_gap` | Closed log files waiting to be archived: the current log minus the oldest unarchived one, counted across the wrap from `S9999999.LOG` to `S0000000.LOG`. 0 when the archiver is idle, 1 while it copies the file just closed |
| `first_failed_log` | The first log file that failed to archive (-1 = none) |

**Shipped alerts:**

- `archive_status` **Critical** when it is `FAILED` (1 occurrence). The message names the archive method, the first failed log file and how many files are waiting.
- `archive_log_gap` **Warning at 5, Critical at 20** log files (2 occurrences, so 30 minutes). A healthy archiver keeps the gap at 0 or 1, and a burst of log writes clears within one collection. Five files waiting for half an hour means archiving is not keeping up, or is stuck without reporting a failure (a hung vendor library, for example).

Each waiting file is a full `LOGFILSIZ` of log that cannot be reused. It sits only in the active log path until it is archived, and adds to that file system, so 20 is the point to act before the path fills. Tune it to your `LOGFILSIZ` and archive speed.

**On an HADR standby**, `archive_status` is `STANDBY`, `archive_log_gap` is 0, and `oldest_unarchived_log` and `first_failed_log` are -1. A standby replays the primary's log, so its current log number keeps moving, but only the primary archives. `STANDBY` raises no alert; watch archiving on the primary's target. The plug-in recognises a standby from the database status (`STANDBY`, or `ACTIVE_STANDBY` with reads on standby), the same read the availability check makes, so it needs no extra privilege.

**Why it matters.** A log file that is not archived cannot be reused, so the active log path keeps growing until its file system is full and the database stops. Until it is archived, the file exists in one place only. `db2diag.log` carries the reason (`ADM1848W`, *Failed to archive log file*), which the [diagnostic log group](#diag-log) reports. Shown on the [Transaction Log page](monitoring-pages.md#transaction-log) as Log Archiving, and as the Logs Waiting to Be Archived trend.

### Tablespace_Storage {#tablespace-storage}

Interval **15 min**. Per table space (`tablespace_id` and `tablespace_name` keys): state, buffer-pool id, page, extent and prefetch size, total, usable, used and free pages, type, current and maximum size, `tablespace_last_resize_failed`, `tablespace_auto_resize_enabled` and `tablespace_utilization` (%). These snapshots feed growth trending and days-to-full forecasting.

**Shipped alerts** (1 occurrence):

| Column | Warning | Critical |
|---|---|---|
| `tablespace_utilization` | above 80 % | above 90 % |
| `tablespace_state` | matches a fault state: `OFFLINE`, `STORAGE_MUST_BE_DEFINED`, `RESTORE_PENDING`, `ROLLFORWARD_PENDING`, `DELETE_PENDING`, `DISABLE_PENDING`, `DROP_PENDING`, `LOAD_PENDING` or `SUSPEND_WRITE` | matches `OFFLINE` |

The state alert is not "anything but NORMAL": `TBSP_STATE` also covers routine transient states, such as an online backup or a rebalance, that must not warn every night.

### Tablespace_Forecast {#tablespace-forecast}

Interval **30 min**. Per table space: `UsedBytes`, `CapacityBytes`, `MaxBytes`, `GrowthBytesPerDay`, `PctUsed` (%), `DaysToFull` (days; `9999` = no forecast), `AutoResize`, `ResizeFailed`, `FsFreeBytes`. **Shipped alerts:** `DaysToFull` Warning below 30, Critical below 7 days (2 occurrences); `ResizeFailed` Critical when equal to 1 (1 occurrence).

`CapacitySource` says what "full" means for each table space:

| Value | Meaning |
|---|---|
| `ALLOCATED` | No auto-resize; it cannot grow past its current size |
| `MAXSIZE` | Auto-resize up to its MAXSIZE, which its file systems can hold |
| `FILESYSTEM` | Auto-resize with no MAXSIZE (the Db2 default), or a MAXSIZE larger than its file systems can hold. The ceiling is what is allocated now plus `FsFreeBytes`, the free space on its storage group's file systems, each counted once |
| `NONE` | No ceiling can be read (an unlimited table space not on automatic storage). Only this case reports `9999` |

Several table spaces in one storage group share its free space, and each projection assumes the others stop growing. Storage_Paths watches the file system itself.

### Storage_Paths {#storage-paths}

Interval **30 min**. One row per storage group and automatic-storage path (`storage_group`, `storage_path` keys), from `ADMIN_GET_STORAGE_PATHS`: `path_state` (`IN_USE`, `UNUSED` for Db2's `NOT_IN_USE`, `DROP_PENDING`), `fs_id`, `fs_total_bytes`, `fs_used_bytes`, `fs_free_bytes`, `fs_used_pct`. A file system that holds several paths appears once per path. **Shipped alert:** `fs_used_pct` Warning above 85 %, Critical above 95 % (1 occurrence). Shown on the [Storage page](monitoring-pages.md#storage) as Storage Paths - File System Headroom.

## Locking {#locking}

The lock groups collect every **5 min**, except Deadlocks (15 min).

Metadata 4.7 retired the connection-keyed lock groups `Lock_Waits`, `Lock_Waits_By_Blkd_App`, `Lock_Waits_By_Blkng_App`, `Open_Transactions` and `Blocking_Chains`. The groups below replace them, and their keys cannot grow with connections. The retired groups' stored data is deleted on the upgrade; thresholds set on them do not move. See [Upgrade notes](upgrade-notes.md#renamed-groups).

**Longest_Lock_Waits** (was `Lock_Waits`). Per lock wait, keyed by `wait_rank` (1 = longest). Only ranks 1 to 25 are stored; the Locks page reads up to 1,000 live. The waiting connection is the `ReqAgent` column. Columns: `LockName`, `ObjectType`, `Schema`, `TableName`, `Duration` (s), and the requesting and holding application, user and statement.

**Lock_Waits_By_Table**, **Lock_Waits_By_Blocked_App** and **Lock_Waits_By_Blocking_App** roll total wait duration up by table, by blocked application and by blocking application. The two application roll-ups are keyed by application name, with `Connections` and `TopHandle`, the connection waiting or blocking longest. Their `Duration` Conditions ship Not Defined.

### Oldest_Transactions {#oldest-transactions}

Was `Open_Transactions`. The oldest open units of work, up to 20, keyed by `age_rank` (1 = oldest); the connection is the `application_handle` column. It covers long-running transactions and **idle-in-transaction** sessions: an application that changed data and then stopped without committing still holds its locks and pins the active log.

For each one you get the application, user, client host, start time, `uow_age_sec`, state, `idle_in_transaction` (YES/NO), log space used, locks held, and `holds_oldest_xact`. The state is the **Unit of Work State**: `UOWEXEC` = running, `UOWWAIT` = waiting for the application, or another Db2 state such as `UOWQUEUED`.

- **What counts as open:** a transaction has written log or holds locks. Db2 starts the next unit of work at every commit, so a merely idle connection is not reported.
- **Shipped alert:** `uow_age_sec` Warning above 1,800 seconds (30 minutes), Critical above 7,200 (2 hours), 1 occurrence. The message names the rank, the application, handle and user, and whether the transaction is idle. The alert is per rank: rank 1 is the oldest transaction of the moment, whichever connection runs it.

### Blocking_Tree {#blocking-tree}

Was `Blocking_Chains`. The lock waits of the moment as trees, built by the collector from `SYSIBMADM.MON_LOCKWAITS` (the view the lock-wait groups read, so no new grant). One row per application in a tree, keyed by `node`, its position in the trees (worst tree first, at most 50).

| Column | Meaning |
|---|---|
| `application_handle` | The application |
| `blocker_handle` | The application it is drawn under; empty for a root blocker. When several applications hold the lock it waits on (a shared lock), it is drawn under the lowest handle, the same every collection |
| `other_holders` | The other holders, comma-separated. They get no row of their own unless they are waiting too or are another waiter's blocker |
| `root_handle`, `chain_depth`, `waiters_below` | The tree's root, the depth (0 = the root blocker), and how many applications wait on it, directly or not |
| `appl_name`, `auth_id`, `client_host` | Who |
| `wait_sec`, `tree_wait_sec` | Its own wait, and the total wait of its tree. `tree_wait_sec` is the same on every row of a tree, so the `LimitRows` cut of 50 keeps trees whole, the worst first |
| `lock_object`, `lock_mode` | The lock |
| `in_cycle` | YES for applications waiting on each other in a circle, a deadlock Db2 has not broken yet. Cycles are found through every holder, not only the drawn ones |
| `stmt_text` | The waiting statement, or a root blocker's current one |

At most 1,000 lock waits are read in one collection. The waits of applications that are themselves holding a contended lock are read first, so a blocker in the middle of a chain is never cut off. The group is empty whenever nothing waits. No thresholds ship: lock waits alert through DB_Monitoring (`average_lock_wait_time`, `percent_appls_waiting_on_lock`) and Wait_Time (`lock_wait_pct`). Shown on the [Locks page](monitoring-pages.md#locks) as **Blocking Chains**.

### Deadlocks (opt-in) {#deadlocks}

Interval **15 min**, **opt-in**. The 20 newest deadlocks of the last 24 hours, one row per participant. Keyed by `event_epoch` + `event_id` + `member` + `participant_no`: Db2 restarts `event_id` when the monitor is re-created, so the deadlock's time is part of the key.

- `event_epoch`: the time, as epoch seconds UTC. Db2 writes `EVENT_TIMESTAMP` in the server's local time, and the plug-in converts it with the server's current offset.
- `event_type` (`DEADLOCK`) and `participants`, how many applications took part.
- `rolled_back`: YES for the one Db2 rolled back, NO for the others, empty if the monitor's lock table does not record it.
- `application_handle`, `appl_name`, `auth_id`, `client_host`.
- `lock_object`, `stmt_hash` and `stmt_text`, the statement each participant was running.

`LimitRows` keeps the 50 newest rows. No thresholds ship: DB_Monitoring's `deadlocks_rate` alerts on the rate, and this group says who and what. Shown on the [Locks page](monitoring-pages.md#locks) as **Recent Deadlocks**.

**Known issue: daylight saving time.** The conversion uses the offset in force when the collection runs, not when the deadlock happened. On a server that observes daylight saving time, a deadlock from the 24 hours before the clocks change is stored under a second `event_epoch`, one hour off, after the change. Recent Deadlocks then lists it twice, an hour apart, until it is a day old. Nothing else is affected.

#### Setting up deadlock capture {#deadlock-capture}

Db2 records deadlock participants only through an event monitor. Creating one is a change to the database, so **the plug-in never creates one**. A DBA does it once per database, as an administrator. The documented name is `IP_DEADLOCKS`, but any name works: the plug-in uses `IP_DEADLOCKS` if it exists, otherwise the first locking event monitor (by name) that writes to tables.

```sql
-- As a DBA (SQLADM or DBADM), connected to the monitored database.
-- 1. A locking event monitor writing to regular tables. Its tables are
--    LOCK_IP_DEADLOCKS, LOCK_PARTICIPANTS_IP_DEADLOCKS,
--    LOCK_PARTICIPANT_ACTIVITIES_IP_DEADLOCKS (and two the plug-in does not read),
--    in the creator's default schema unless you name one.
CREATE EVENT MONITOR IP_DEADLOCKS FOR LOCKING
    WRITE TO TABLE
        LOCK (TABLE LOCK_IP_DEADLOCKS),
        LOCK_PARTICIPANTS (TABLE LOCK_PARTICIPANTS_IP_DEADLOCKS),
        LOCK_PARTICIPANT_ACTIVITIES (TABLE LOCK_PARTICIPANT_ACTIVITIES_IP_DEADLOCKS),
        LOCK_ACTIVITY_VALUES (TABLE LOCK_ACTIVITY_VALUES_IP_DEADLOCKS),
        CONTROL (TABLE CONTROL_IP_DEADLOCKS)
    AUTOSTART;
SET EVENT MONITOR IP_DEADLOCKS STATE 1;

-- 2. Let the monitoring user read the three tables the plug-in reads
--    (SQLADM does not cover table data). Use the schema the tables were created in.
GRANT SELECT ON LOCK_IP_DEADLOCKS TO USER <monitoring_user>;
GRANT SELECT ON LOCK_PARTICIPANTS_IP_DEADLOCKS TO USER <monitoring_user>;
GRANT SELECT ON LOCK_PARTICIPANT_ACTIVITIES_IP_DEADLOCKS TO USER <monitoring_user>;
```

Then check, or set, the database configuration that decides what Db2 sends to the monitor:

- `MON_DEADLOCK` must not be `NONE`. Its default, `WITHOUT_HIST`, records each participant's current statement, which is what this group shows. `HISTORY` also records earlier statements of the unit of work, at some cost.
- Leave `MON_LOCKTIMEOUT` and `MON_LOCKWAIT` at `NONE` unless you also want those events. Each adds rows to the same tables, and the plug-in reads only deadlocks.

**Keep the tables small.** The tables grow with every lock event. Prune them on a schedule, for example by deleting rows older than 30 days from all five tables, or `DROP` and re-create the monitor; the plug-in only ever reads the last 24 hours. Every 15 minutes the plug-in reads the lock table for the newest deadlocks of the last day, then their participants and statements by the event's `EVENT_ID` and `EVENT_TIMESTAMP` (a monitor that writes to tables has no `XMLID`). On a large table that read scans it, so index the columns it filters and joins on:

```sql
CREATE INDEX LOCK_IP_DEADLOCKS_IX ON LOCK_IP_DEADLOCKS (EVENT_TYPE, EVENT_TIMESTAMP);
CREATE INDEX LOCK_PARTICIPANTS_IP_DEADLOCKS_IX ON LOCK_PARTICIPANTS_IP_DEADLOCKS (EVENT_ID, EVENT_TIMESTAMP, PARTICIPANT_NO);
CREATE INDEX LOCK_PARTICIPANT_ACTIVITIES_IP_DEADLOCKS_IX ON LOCK_PARTICIPANT_ACTIVITIES_IP_DEADLOCKS (EVENT_ID, EVENT_TIMESTAMP, PARTICIPANT_NO);
```

To stop capture: `SET EVENT MONITOR IP_DEADLOCKS STATE 0`, then `DROP EVENT MONITOR IP_DEADLOCKS` and drop its tables.

**Until all of this is in place**, Deadlocks is empty and its CollectorStatus row reads **NOT_CONFIGURED** with the reason:

- no event monitor, or the monitor is not active
- `MON_DEADLOCK` is set to `NONE` (Db2 then sends no deadlock to any monitor, whatever a workload's `COLLECT DEADLOCK DATA` says)
- a missing table or column, or no `SELECT` grant

The Recent Deadlocks region shows that reason. With capture set up and no deadlock in 24 hours, the status is **NO_DATA**.

## HADR {#hadr}

Two groups. The [HADR monitoring](hadr-monitoring.md) page covers them in full, with [their default alerts](hadr-monitoring.md#default-alerts) and [monitoring a standby](hadr-monitoring.md#monitoring-a-standby).

**HADR_Status**, interval **15 min**, key `DbName`. Columns include `HadrRole`, `HadrState`, `HadrSyncMode`, `HadrConnectStatus`, `HadrConnectTime`, `HadrHeartbeat` (labelled `Heartbeats Missed (count)`), local and remote host, service and instance, `HadrTimeout`, the primary log file and page, the primary and standby log positions in bytes (`HadrPrimaryLogLsn`, `HadrStandbyLogPos`), and the standby log file. **Shipped alert:** `HadrConnectStatus` Warning when `CONGESTED`, Critical when `DISCONNECTED` (1 occurrence).

**HADR_Readiness**, interval **5 min**, key `DbName` + `StandbyId`, one row per standby. It adds:

- `ValuesLive`: YES while the pair is connected, NO when the gap and lag columns hold last-known values, because Db2 stops updating them during a disconnect.
- A takeover-readiness composite, `TakeoverReady`: Critical when equal to 0 (2 occurrences); `-1` = auxiliary standby, which never alerts.
- Log-gap, replay-gap and replay-lag columns.

| Column | Operator | Warning | Critical | Occurrences |
|---|---|---|---|---|
| `HadrLogGap` | Greater Than | 10 MB | 100 MB | 3 |
| `RecvReplayGap` | Greater Than | 10 MB | 100 MB | 3 |
| `ReplayLagSec` | Greater Than | 60 s | 300 s | 3 |
| `StateAlert` | Matches | anything but `OK` | none | 2 |

A healthy PEER pair measures exactly 0 on every gap and on the lag. `StateAlert` is `OK` when the standby is in PEER, or in REMOTE_CATCHUP under SUPERASYNC; auxiliary standbys are always `OK`. Otherwise it holds the unexpected state, which the alert names.

## DB_Backup {#db-backup}

Interval **30 min**. `db_name` (key), `server_instance_name`, `last_backup` (timestamp), `days_since_last_backup`. **Shipped alert:** `days_since_last_backup` Warning greater than 1 day, Critical greater than 3 days (3 occurrences). On a partitioned database it reports the oldest partition's backup (see [DPF](#dpf)). Shown on the [Backup page](monitoring-pages.md#backup).

## Recovery history, utilities and rebalance {#recovery-history}

**DB_History**, interval **1 hr**. From `SYSIBMADM.DB_HISTORY`: backup (`B`), restore (`R`), load (`L`), reorg (`G`) and rollforward (`F`) entries, keyed by `eid`.

- `operation` and `operation_name` (decoded Backup, Restore, Load, Reorg, Rollforward), `operationtype`, `objecttype`.
- `start_time`, `end_time`, `entry_status`, `sqlcode`, `num_tbsps`, `devicetype`, `location`, `backup_id`, `comment`.
- The derived `operation_failed`: 1 when SQLCODE is negative.

**Shipped alert:** `operation_failed` Critical when equal to 1 (1 occurrence). It flags a failed backup, restore, load, reorg or rollforward. A failed reorg is recorded too, for example `SQL0668N` on a table in load-pending state.

`objecttype` is `D` database, `P` table space, `T` table, `I` index or `R` partitioned table. `operationtype` depends on the operation: for a backup `F` offline, `N` online, `I` incremental, `D` delta; for a reorg `F` offline, `N` online; for a rollforward `E` to end of logs, `P` to a point in time. The 100 most recent entries are kept, so on a database with frequent automatic reorgs older backups can drop out of this list. [DB_Backup](#db-backup) still tracks the last backup on its own.

**Utilities**, interval **15 min**. The utilities running now, from `MON_GET_UTILITY`: up to 50, oldest first, keyed by `utility_id`.

| Column | Meaning |
|---|---|
| `utility_type` | For example `LOAD`, `BACKUP`, `RESTORE`, `RUNSTATS` |
| `operation_type`, `invoker_type` | `invoker_type` is `USER` or `AUTO` |
| `object_type`, `object_name` | The object, as schema.name |
| `application_handle`, `appl_name`, `auth_id` | Who invoked it |
| `start_time`, `elapsed_sec` | When it started and how long it has run |
| `utility_priority` | Throttling; 0 = unthrottled |
| `utility_detail` | Db2's own one-line description, up to 1,000 characters |

**Shipped alert:** `elapsed_sec` Warning above 8 hours (28,800 s), Critical above 24 hours (86,400 s), 1 occurrence. Raise it per target for a database whose full backup routinely runs longer.

There is no progress or state column. Db2 reports those only through the discontinued `SNAP_GET_UTIL` and `SNAP_GET_UTIL_PROGRESS` functions, which the plug-in does not use and which the least-privilege monitoring user cannot run (`SQL1092N`). For a running utility's progress, use `db2 list utilities show detail` on the server.

**Rebalance_Status**, interval **15 min**. Table spaces being rebalanced across storage paths or storage groups, from `MON_GET_REBALANCE_STATUS`, keyed by `tbsp_name`: `rebalancer_mode`, `rebalancer_status` (`ACTIVE` or `SUSPENDED`), `extents_processed`, `extents_remaining` (Db2's estimate), `percent_complete`, `start_time`, `restart_time`, `elapsed_sec`, `source_stogroup`, `target_stogroup` and `rebalancer_priority`. No alert ships: a rebalance can rightly run for hours.

A **suspended** rebalance can read `0` moved, `0` remaining and `0` % complete: Db2 restarts a suspended rebalancer from time to time and resets its counts (seen on Db2 12.1.4). The counts are right again once it is resumed.

The [Backup page](monitoring-pages.md#backup) shows the last backup and the days since it, the recovery history, and Running Utilities and Table Space Rebalance when something is running. Utilities and Rebalance_Status are empty when nothing is running, and their CollectorStatus row then reads `NO_DATA`.

## Top SQL {#top-sql}

**Top_Queries_Cpu_Time** and **Top_Queries_Execution_Count**, interval **30 min**. Top statements keyed by `StmtHash`, a hash of the statement's exact text. Unlike Query_Analytics, which groups by digest (see the [SQL page](monitoring-pages.md#sql)), the cumulative counters here are per cached statement. Only the top 5 are kept each collection.

Columns: `StmtText` (the statement's SQL text), `CpuTime` (ms) and `CpuTimePerHour`; `ExecutionCount` and `ExecutionCountPerHour`. Delta-aware per-statement workload trends. The alert messages on these groups include the statement text; the `CpuTimePerHour` and `ExecutionCountPerHour` Conditions (2 occurrences) ship Not Defined.

The [SQL page](monitoring-pages.md#sql) reads the per-statement `Query_Analytics` group and the **SQL Statement Text** group (`Statement_Text`, interval 15 min). Statement_Text stores each statement's text under the same hash at most once a day, and the text is kept in the Enterprise Manager repository.

**Statement text and literal values.** From 24.1.2.0.0 / 13.5.3.0.0 the SQL Statement Text group stores the digest text, without literal values (see [What's new](whats-new.md#statement-text-privacy)). Text it collected earlier, and the statement text in Top SQL, Top_Sessions, the lock groups and Deadlocks, is the SQL as it ran and can contain literal values from the application. To stop collecting the SQL Statement Text group, disable **SQL Statement Text** for the target in **Monitoring → Metric and Collection Settings → Other Collected Items**. Top Statements then shows its numbers without the text.

## Configuration inventory {#configuration}

**Db2DatabaseConfiguration**, interval **24 hr**. A daily snapshot of 18 configuration groups, stored as configuration data for change tracking and compliance:

- System, Partition, Instance, Registry_Setting
- the Dbm_* groups (Capacity, Log_Recovery, Connection, Partitioned_Env, DbInstance)
- Product, Recovery, Audit Posture, Memory and STMM
- from metadata 4.5: Security and Maintenance, Buffer Pools, Table Spaces, HADR, and Authorities and Privileges

The [Configuration page](monitoring-pages.md#configuration) shows it, searchable, with the latest changes highlighted, under the DB CFG and DBM CFG areas. The database's logging and recovery settings (`IBM_DB2_DB_Recovery`) are also shown on the [Transaction Log page](monitoring-pages.md#transaction-log). The [compliance standards](compliance-standards.md#rules) read several of these groups.

**Memory and STMM** (`IBM_DB2_DB_Memory`, *Database Configuration : Memory and STMM*):

| Column | Values |
|---|---|
| `self_tuning_mem` | `ON` or `OFF` |
| `database_memory` | `AUTOMATIC`, `COMPUTED`, or a size in 4 KB pages |
| `instance_memory` | `AUTOMATIC` or a size in 4 KB pages |
| `stmm_auto_params` | The STMM-tunable parameters set to `AUTOMATIC` (`LOCKLIST`, `MAXLOCKS`, `PCKCACHESZ`, `SHEAPTHRES_SHR`, `SORTHEAP`); `NONE` when none is |

`AUTOMATIC` is recorded as the word, not the size STMM has tuned to, so the snapshot changes only when someone changes the configuration. STMM tunes nothing unless at least two memory consumers are `AUTOMATIC`, whatever `self_tuning_mem` says, so read the two together. `stmm_auto_params` lists configuration parameters only. STMM also tunes every buffer pool whose size is `AUTOMATIC` (`NPAGES` -2 in `SYSCAT.BUFFERPOOLS`), and each of those counts as a memory consumer too.

**Database Configuration : Security and Maintenance** (`IBM_DB2_DB_Security`):

- The instance's `AUTHENTICATION`, `SRVCON_AUTH`, `ALTERNATE_AUTH_ENC`, `CATALOG_NOAUTH`, `TRUST_ALLCLNTS`, `TRUST_CLNTAUTH`, `DISCOVER`, `DISCOVER_INST`, `SSL_SVCENAME` and `SSL_VERSIONS`.
- The database's `DISCOVER_DB`, `RESTRICT_ACCESS`, `LOCKTIMEOUT` (seconds, -1 = wait forever), `AUTO_MAINT`, `AUTO_TBL_MAINT`, `AUTO_RUNSTATS`, `AUTO_REORG`, `AUTO_DEL_REC_OBJ`, `ENCRLIB` and `ENCROPTS` (backup encryption).
- A parameter a Db2 release does not have is left empty.
- `days_since_last_backup` at collection time (-1 = never backed up; computed as DB_Backup computes it), which the backup-recency rule reads.

`days_since_last_backup` is the one value in the snapshot that changes with nobody changing anything. While no backup is taken it grows by one a day, and that daily change is what makes Enterprise Manager re-check the rule. So the configuration history records up to one change a day for a database not backed up daily, and the comparison template and the Configuration page ignore it.

**Database Configuration : Buffer Pools** (`IBM_DB2_DB_Bufferpool`). One row per buffer pool, from `SYSCAT.BUFFERPOOLS`: page size in bytes, configured size in pages (-2 = `AUTOMATIC`), `size_mode` (`AUTOMATIC` or `FIXED`) and the block-based area in pages. The configured size, not the size STMM has tuned an automatic pool to, so it changes only when someone alters the pool.

**Database Configuration : Table Spaces** (`IBM_DB2_DB_Tablespace`). One row per table space: type (`SMS` or `DMS`), content (`ANY`, `LARGE`, `SYSTEMP`, `USRTEMP`), page size in bytes, extent and prefetch size in pages (prefetch -1 = `AUTOMATIC`), storage group, automatic storage and auto-resize (0/1), maximum size in bytes (-1 = no limit) and dropped-table recovery (`Y`/`N`). Space in use is in [Tablespace_Storage](#tablespace-storage), not here.

**Database Configuration : HADR** (`IBM_DB2_DB_Hadr_Config`): `HADR_LOCAL_HOST`, `HADR_LOCAL_SVC`, `HADR_REMOTE_HOST`, `HADR_REMOTE_SVC`, `HADR_REMOTE_INST`, `HADR_TARGET_LIST`, `HADR_SYNCMODE`, `HADR_TIMEOUT`, `HADR_PEER_WINDOW`, `HADR_REPLAY_DELAY` (seconds), `HADR_SPOOL_LIMIT` (`AUTOMATIC` as the word), `HADR_SSL_LABEL`, `LOGINDEXBUILD` and `BLOCKNONLOGGED`. One row on every database; empty HADR columns mean HADR is not configured. Host names, service ports and the target list differ on every database, so a configuration comparison ignores them.

These four read `SYSIBMADM.DBMCFG`, `SYSIBMADM.DBCFG` and `MON_GET_TABLESPACE`, which the `SQLADM` monitoring user already reads, and the `SYSCAT.TABLESPACES` and `SYSCAT.BUFFERPOOLS` catalog views, readable by `PUBLIC` by default. A hardened database needs the optional grant in [Prerequisites](prerequisites.md#monitoring-role). They are new groups only, so an upgraded OMS needs no restart.

**Authorities and privileges** (`IBM_DB2_DB_Privileges`, *Database Authorities and Privileges*). One summary row:

- `public_default_auths`: which of `BINDADD`, `CONNECT`, `CREATETAB` and `IMPLICIT_SCHEMA` `PUBLIC` holds, or `NONE`.
- `public_admin_auths`: any other database authority `PUBLIC` holds, or `NONE`.
- How many user tables and views `PUBLIC` has a privilege on and can change, and the first five by name.
- How many user routines it can execute (a grant on every routine of a schema counts once).
- The number of DBADM and SECADM holders and the first ten of each (`U` user, `G` group, `R` role).
- The enabled user-defined trusted contexts, with how many let `PUBLIC` switch in without authentication.

Db2's own schemas are left out. Neither count includes Db2's own `SYSATSCONTEXT`, which Db2 creates with every database for the Administrative Task Scheduler, on system authorization ID `SYSATS`, open to `PUBLIC` without authentication; no user can connect as `SYSATS`. If it is given a default role, or moved to another system authorization ID, it is counted. The [compliance privilege rules](compliance-standards.md#rules) read it. The Configuration page shows it under **Audit posture**.

It reads `SYSCAT.DBAUTH`, `TABAUTH`, `ROUTINEAUTH`, `CONTEXTS` and `SURROGATEAUTHIDS`, readable by `PUBLIC` by default. A hardened database needs the optional grant in [Prerequisites](prerequisites.md#monitoring-role). Without it this group collects nothing, and CollectorStatus reports it NOT_CONFIGURED, naming the grant, with no collection error and no alert. The same holds for *Buffer Pools* and *Table Spaces* when `SYSCAT.BUFFERPOOLS` or `SYSCAT.TABLESPACES` is revoked.

## Diagnostic log {#diag-log}

**Diag_Log_File_Monitoring**, interval **30 min**. A pattern-matched scan of the Db2 diagnostic log (`<DIAGPATH>/db2diag.log`), reading only what was written since the last collection. Columns: `count` (matches since the last collection, per function), `server`, `instance`, `db`, `function`, `timestamp`, `message` and `message_text`.

**Shipped alert:** `count` Warning greater than 0, Critical greater than 3 matches. The alert text is the matched message, from `message_text`. The latest matches are listed on the [Locks page](monitoring-pages.md#locks) under **Diagnostic Log Matches**, and on the instance target's [Diagnostics page](monitoring-pages.md#diagnostics-instance).

**Local only.** The group needs the agent to be on the Db2 server (the `local` property is 1).

**Where the message is stored.** `message_text` (*Message Text*) holds the matched record's message, up to 4,000 bytes. A longer one is cut, without splitting a character, and ends in `truncated ...`. Read the message from `message_text`, in the console, in reports and over MCP. `message` carries the same text and is kept, unchanged, for compatibility, but on Enterprise Manager 24ai it never reaches the repository.

**After upgrading an OMS that already ran an earlier version of this plug-in, restart the OMS** (`emctl stop oms`, then `emctl start oms`) once the plug-in is deployed. Until then `message_text` stays empty and the alert text is blank. The OMS keeps each target type's list of metric columns in memory, and deploying a new plug-in version does not refresh that list. A new OMS install needs no restart. See [Upgrade notes](upgrade-notes.md#restart-oms).

**Patterns shipped by default:**

| What | Pattern |
|---|---|
| Any administration-notification error or critical message | `\bADM\d{4,5}[CE]\b` |
| Unexpected system error; agent or connection terminated | `SQL1042C`, `SQL1224N` |
| Active log full; nearly full | `ADM1823E`, `ADM1822W` |
| Table space full | `ADM6017E`, `ADM6019E` |
| HADR connection lost; standby error | `ADM12504E`, `ADM12511E` |
| Log file failed to archive (a warning, so listed by name) | `ADM1848W` |
| Records Db2 classes as critical | `LEVEL: Critical` |
| Traps, panics, crash data capture | `FODC_Trap` (and `_Panic`, `_BadPage`, `_IndexError`, `_DataError`, `_Hang`), `SIGSEGV`/`SIGBUS`/`SIGILL`/`SIGABRT`/`SIGFPE`, `panic` |

Each line of a pattern file is one Perl regular expression, matched case-insensitively against a whole `db2diag.log` record (its lines joined with spaces). Blank lines and lines starting with `#` are ignored. A line that is not a valid expression is skipped and reported as a warning instead of failing the collection.

**Which target reports a record.** One `db2diag.log` serves every database of the instance. A record that names a database (`DB : <name>`) is reported only by that database's target. A record that names none (an instance-level message) is reported by every target of the instance.

**Your own patterns survive upgrades.** The packaged files live in the versioned plug-in home and are replaced by every upgrade, so do not edit them. Put your copy in the agent state directory, beside the plug-in's `lib` directory:

```
<agent state dir>/ip_plugin/xdb2/Diag_log_file_match_pattern_file.txt      (match patterns)
<agent state dir>/ip_plugin/xdb2/Diag_log_file_no_match_pattern_file.txt   (ignore patterns)
```

A file there replaces the packaged file of the same name entirely, so start from a copy of the packaged one and keep the lines you still want. The ignore file ships empty; a record matching an ignore pattern is never reported. Changes take effect at the next collection, with no agent restart.

## CollectorStatus {#collectorstatus}

Interval **5 min**. Why each metric group on this target is empty, or that it is not. One row per collected metric group, keyed by `MetricGroup`:

| Column | Meaning |
|---|---|
| `Status` | One of `OK`, `NOT_CONFIGURED`, `NOT_COLLECTED_YET`, `NO_DATA`, `COLLECTION_ERROR`, `DISABLED` |
| `Reason` | The reason in plain language |
| `RowsReturned` | Rows the group's last collection returned |
| `LastAttemptEpoch` | When the agent last tried, in seconds since 1970-01-01 UTC. `LastAttempt`, its text form, is empty from metadata 4.2 |
| `LastDurationMs` | How long the group's last collection took; empty when no timed attempt exists yet |
| `ConsecutiveErrors` | How many attempts in a row ended in `COLLECTION_ERROR`; any other outcome resets it to 0 |

A group that has failed 12 times in a row is a different problem from one that failed once. A group whose duration creeps up is a query getting slower before it times out.

- **A legend row.** Each collection carries a row whose `MetricGroup` is `_Vocabulary`, spelling the whole status vocabulary out. Row order over MCP follows the key column, so locate it by key, not by position.
- **Unsupported versions.** On an unsupported Db2 version or topology every group except `Response` (and `Version`, the detection itself) reads `DISABLED` with the reason (see [Supported versions](index.md#supported-versions)).
- **Shipped alert:** `Status` Critical when it matches `COLLECTION_ERROR`, after 2 occurrences, with the group name and the reason carried into the alert. No other status alerts.
- **It collects while the target is down.**

CollectorStatus exists mainly for AI clients reading this plug-in over the MCP server, which otherwise cannot tell an empty metric group from a broken one. See [CollectorStatus in the MCP server page](mcp-server.md#collectorstatus) and [an empty metric group](troubleshooting.md#empty-group).

### readiness_summary {#readiness-summary}

*Monitoring Readiness Summary*, interval **60 min**, metadata 4.9. The Monitoring Readiness checks counted by status, in one row: `ok_count`, `warn_count` (needs attention), `fail_count` (not functional) and `unknown_count` (could not be judged).

It runs the same checks as the [Monitoring Readiness page](monitoring-pages.md#monitoring-readiness) and counts them the way the page does. An optional check (HADR, deadlock capture, the diagnostic log) counts at most as needing attention, and one that could not be judged counts as OK. The Overview's **Monitoring and License** card reads its newest row, so `warn_count` + `fail_count` is the card's "checks need attention", up to an hour old; the Monitoring Readiness page checks live. Like CollectorStatus, it collects when the database is down and without a valid licence, and it has no alert.

## Monitor_Metrics {#monitor-metrics}

Interval **60 min**. The three DB CFG switches that decide whether Db2 counts metrics at all:

- `mon_req_metrics`: request metrics (CPU, rows, waits).
- `mon_act_metrics`: activity metrics (per-statement work).
- `mon_obj_metrics`: object metrics (buffer pool and table space I/O).

Each is `NONE`, `BASE` or `EXTENDED`. At `NONE`, the `MON_GET_*` functions this plug-in reads still return rows, **full of zeros**, so performance metrics look healthy while measuring nothing. `metrics_off` is `OK`, or the names of the switches at `NONE`.

**Shipped alert:** Warning when `metrics_off` is anything but `OK` (1 occurrence). The message gives the fix:

```
db2 update db cfg for <database> using MON_REQ_METRICS BASE MON_ACT_METRICS BASE MON_OBJ_METRICS BASE
```

The change takes effect online. **Which databases are affected:** a database created on Db2 9.7 or later defaults to `BASE` (`mon_obj_metrics`: `EXTENDED`), but one created before 9.7 and upgraded since keeps `NONE` (IBM, `mon_req_metrics` configuration parameter). Upgraded databases are therefore the ones to check.

## Shipped thresholds and templates {#shipped-thresholds}

The full list of thresholds that ship with values, the three monitoring templates (Starter, Standard and Production-critical) and the optional incident rule set, configuration comparison template and drift definition that ship beside the plug-in are on the alerts page:

- [Default thresholds](alerts-and-templates.md#default-thresholds): every shipped Warning and Critical value, and how to confirm them with `emcli get_threshold`.
- [Monitoring templates](alerts-and-templates.md#monitoring-templates): what each template sets, and how to import and apply it.
- [Incident rules](alerts-and-templates.md#incident-rules): the rule set, configuration comparison and drift, and what to expect from each.

## WLM {#wlm}

**WLM_Workloads** and **WLM_Service_Classes**, interval **15 min**. Db2 workload management (WLM) sorts incoming work into **workloads** (by who or what connects) and runs it in **service classes** (a superclass with subclasses), where thresholds can limit how many activities run at once and queue the rest. The two groups, from `MON_GET_WORKLOAD` and `MON_GET_SERVICE_SUBCLASS`, report each workload's and each service subclass's work over the interval since the previous collection:

| Column | Meaning |
|---|---|
| `workload_name` (key), or `service_superclass_name` + `service_subclass_name` (keys) | The workload, or the service subclass |
| `interval_sec` | The seconds the row covers, by the database clock |
| `app_rqsts_completed` | Application requests completed |
| `act_completed`, `act_aborted`, `act_rejected` | Coordinator activities (statements, loads, calls) that completed, ended in error, or were rejected by a WLM threshold instead of being allowed to run |
| `wlm_queue_assignments` | Activities a WLM queuing threshold put in a queue |
| `wlm_queue_time_ms` | Time they spent queued, summed (`WLM_QUEUE_TIME_TOTAL`) |
| `avg_queue_time_ms` | Queue time per queued activity |
| `queue_time_pct` | Queue time as a share of request time (`TOTAL_RQST_TIME`, of which queue time is a part). **0 below 10 ms of request time per second of the interval** (9 seconds over 15 minutes), Wait_Time's rate floor |
| `rqst_time_ms`, `act_time_ms` | Request time and activity execution time, in ms |
| `cpu_time_ms` | CPU time used (`TOTAL_CPU_TIME`, which Db2 reports in microseconds) |
| `cpu_share_pct` | This row's share of the CPU all rows of the group used in the interval: which workload or class is using the machine. It is a share of the rows read: up to 500 workloads or subclasses, the most request time since activation first, so on a database with more than that the long tail is not in the total |
| `rows_read` | Rows read from tables |

**A database with only the default WLM objects still shows rows.** Every workload and every subclass is listed every cycle, idle ones included:

- `SYSDEFAULTUSERWORKLOAD` (all user work) and `SYSDEFAULTADMWORKLOAD`.
- The subclasses of `SYSDEFAULTUSERCLASS` (`SYSDEFAULTSUBCLASS`, and on Db2 12.1 `SYSMEDIUMSUBCLASS`, `SYSCOMPLEXSUBCLASS` and `SYSLOADSUBCLASS`), `SYSDEFAULTMAINTENANCECLASS` (automatic maintenance) and `SYSDEFAULTSYSTEMCLASS`.

On such a database the queue columns read 0, because no queuing threshold exists, and `cpu_share_pct` splits CPU between user work and maintenance. These are [interval deltas](#interval-semantics): the first collection records a baseline and writes no row.

**Shipped alert:** `WLM_Service_Classes : queue_time_pct` Warning above 30, Critical above 60 %, over 2 occurrences (30 minutes): a service class's activities spent that share of their request time waiting for a WLM concurrency limit to let them run. It can only fire where an admission limit exists: one a DBA created, or the default `SYSDEFAULTCONCURRENT` threshold that Db2 enables on a database created with `DB2_WORKLOAD=ANALYTICS`. A class that is throttled on purpose, such as a low-priority batch class, takes a higher threshold for its key.

**On a database created with `DB2_WORKLOAD=ANALYTICS`, set a per-key override.** There `SYSDEFAULTCONCURRENT` admits only a few heavy queries at a time and queues the rest in `SYSDEFAULTUSERCLASS` / `SYSDEFAULTMANAGEDSUBCLASS` by design. A busy analytics database can spend a third of that subclass's request time queued while healthy.

1. In the console, open **Monitoring → Metric and Collection Settings** and edit `queue_time_pct` under WLM_Service_Classes.
2. Add a row for the key `SYSDEFAULTUSERCLASS` / `SYSDEFAULTMANAGEDSUBCLASS`, with thresholds that match how much queueing you accept (or none). The other subclasses keep 30 / 60.

`emcli modify_threshold` sets the same per-key threshold (see `emcli help modify_threshold` for the key-value argument on your Enterprise Manager release). No runbook in this plug-in references `queue_time_pct`, so nothing else needs changing.

`WLM_Workloads : queue_time_pct` ships Not Defined, because the same queueing reaches the workload and its service class, and one episode should raise one alert. `act_rejected` ships Not Defined on both, because a rejection is a threshold doing what it was configured to do. You can set any of them.

The counters are request metrics: with `MON_REQ_METRICS` at `NONE` they stay at 0 ([Monitor_Metrics](#monitor-metrics) alerts on that). Reading the WLM table functions needs no WLM licence; IBM restricts only creating service classes, workloads, thresholds and work action sets. The existing `SQLADM` grant is enough.

## Partitioned (DPF) databases {#dpf}

From metadata 4.6 (24.1.2.0.0 / 13.5.3.0.0) a partitioned (DPF) database is supported (see [Supported versions](index.md#supported-versions)). Every `MON_GET_*` read asks for all active members (`-2`), and each group then reports the database as a whole, under the same keys it uses on a single member. Stored data and thresholds carry over, and a single-member database reports exactly what it did before.

| Kind of figure | On DPF | Examples |
|---|---|---|
| Counters and sizes that add up | Summed over the members | buffer-pool reads, rows read, table-space pages, connections |
| Ratios | Numerator and denominator summed, then divided | hit ratios, wait-time shares |
| High-water marks | The highest member | agents registered at peak, sort-heap top |
| A size against a limit each member has on its own | The member closest to its limit | log space used, lock list in use, instance memory |
| States | The worst member | database status, table-space state |
| Restart clocks | The latest restart of any member | so a member restart reads as a counter reset, never as a negative rate |
| Last backup | The oldest partition's backup; a partition never backed up means never | `DB_Backup`, the backup-recency compliance rule |

Two things are per member on purpose. [FCM_Buffers](#memory) keeps one row per member, and [DB_History](#recovery-history) lists the recovery history of the catalog partition, because each partition keeps its own history file and their entry numbers repeat.

**Member_Status**, interval **5 min**, collected on DPF and pureScale only. One row per configured member, key `member`:

| Column | Meaning |
|---|---|
| `member` (key), `host_name`, `partition_number` | The member, its host and the database partition it serves, from `DB_MEMBERS()` |
| `member_active` | 1 when the member's instance is up, 0 when it is configured but reports nothing |
| `db_status` | The database's state on that member; `INACTIVE` when the member is up but the database is not active there, `DOWN` when the member is down |
| `connections` | Applications connected through the member |
| `log_used_pct` | The member's active log in use (each DPF partition has its own log) |
| `cpu_time_ms`, `cpu_pct_of_core` | The database's CPU time on the member (cumulative), and its rate over the interval as a percentage of one core |
| `data_bytes` | Used space of the permanent table spaces on the member: the data skew between partitions. Empty on pureScale, where every member shares the table spaces |
| `members_configured`, `members_active`, `members_down` | The database-wide counts, the same on every row |

**Alert:** Critical when `member_active` = 0 (1 occurrence), on the down member's own row, for example "Db2 member 1 on host `<host>` is down: 1 of 2 configured members are active". A member that is down returns no row from any `MON_GET_*` function, so the group reads the configured members from `DB_MEMBERS()` and marks the ones that report nothing. `SYSIBMADM.DB2_MEMBER.STATE` is empty off pureScale and is not used.

On DPF, activate the database (`ACTIVATE DATABASE`) so it is active on every partition. A partition where it is not yet active reads `INACTIVE` (not down, no alert) until its first use.

## pureScale {#purescale}

Three groups collect only on a Db2 pureScale database (`dbTopology` = `PURESCALE`, Db2 11.5 or 12.1; metadata 4.6). [Member_Status](#dpf) also collects on pureScale. Every other group stays off on pureScale, and CollectorStatus says why.

> **Not certified on a pureScale cluster.** These groups are written from IBM's documentation and verified to run on a single-member Db2 12.1.4, where the views exist but hold no pureScale state. No pureScale cluster has run them, so treat their values as unverified until your first collections look right.

**PureScale_Members**, interval **5 min**, one row per member, from `SYSIBMADM.DB2_MEMBER`. Home host, current host, state (`STARTED`, `STOPPED`, `RESTARTING`, `WAITING_FOR_FAILBACK`, `ERROR`), alert (`YES`/`NO`), Restart Light (1 when the member runs on another member's host after a failure), and Member Severity:

- 0: OK.
- 1: `RESTARTING`, `WAITING_FOR_FAILBACK`, an alert, restart light, or a state the plug-in does not recognise.
- 2: `STOPPED` or `ERROR`.

**Alert:** Warning at 1, Critical at 2 (1 occurrence). A planned `db2stop` of a member raises the Critical, so use a blackout for maintenance.

**PureScale_CFs**, interval **5 min**, one row per cluster caching facility, from `SYSIBMADM.DB2_CF` and `MON_GET_CF`. Host, state (`PRIMARY`, `PEER`, `CATCHUP (n%)`, `BECOMING_PRIMARY`, `RESTARTING`, `STOPPED`, `ERROR`), alert, CF Healthy (1 for `PRIMARY`, `PEER` or `CATCHUP`) and CF Severity:

- 0: `PRIMARY` or `PEER`.
- 1: `CATCHUP` (the secondary cannot take over until it reaches `PEER`), `BECOMING_PRIMARY`, `RESTARTING`, an alert, or an unrecognised state.
- 2: `STOPPED` or `ERROR`.

It also reports this database's group buffer pool, lock and shared communication area memory (in use, configured and target) and the CF's memory, in bytes (IBM reports 4 KB pages). **Alert:** Warning at 1, Critical at 2 (1 occurrence).

**PureScale_GBP**, interval **15 min**, one row per member. The cumulative count of times the group buffer pool was full, the GBP logical and physical reads (data and index), the GBP-full rate per minute since the previous collection (0 after a restart), and the GBP hit ratio over the same interval (100 when fewer than 100 GBP reads happened). **Alert:** Warning when the GBP was full more than once a minute (IBM's sizing rule: raise `CF_GBP_SZ`).

A state the plug-in cannot read (NULL) shows an empty severity, never 0. The groups read with `CONNECT` + `SQLADM`, the documented grant (see [Prerequisites](prerequisites.md#monitoring-role)).

## Other database groups {#other-groups}

A few more groups on the IBM Db2 Database target, from the plug-in's metadata:

| Group (console name) | Interval | What it reports | Shipped alert |
|---|---|---|---|
| `License` (Plugin License) | 15 min | The plug-in's own licence state: `license_status`, `license_severity` and `days_remaining`. Collects even while the target is down. See [Licence statuses](targets-and-properties.md#licence-statuses) | `license_severity` Warning at 1, Critical at 2; `days_remaining` Warning below 30, Critical below 7 |
| `Db2_License_Usage` (Db2 Licence and Usage Telemetry) | 2 hr | Db2's own licence telemetry, one row per product offering (`feature_name` key), from `SYSIBMADM.ENV_FEATURE_INFO`: `license_installed` (0/1) and `feature_use_status`. This is the Db2 server's licence, not the plug-in's | `feature_use_status` Warning when `IN_VIOLATION` |
| `Agent_Perf` (IO Agents Performance) | 15 min | Page cleaner activity: `pool_dirty_pg_steal_clns` and `pool_dirty_pg_thresh_clns`. More steal cleans relative to threshold cleans means cleaning is reactive rather than proactive | None (Not Defined) |
| `Table_Properties` (Table Properties (12.1.5)) | 2 hr | Per table, when its Table Control Block was loaded and when the table was last used, with both ages in seconds (`tcb_load_age_sec`, `tcb_idle_sec`). Empty below Db2 12.1.5 | None (Not Defined) |
| `Query_Analytics` (SQL Statement Analytics) | 15 min | Per statement hash, per interval: executions, activity, CPU and lock-wait time (ms), rows read, and `Evicted` (1 = a partial interval, so treat that row's numbers as undercounted). Feeds the [SQL page](monitoring-pages.md#sql) | None |
| `Statement_Text` (SQL Statement Text) | 15 min | Each statement's text under the same hash; see [Top SQL](#top-sql) | None |
| `readiness_detail` (Monitoring Readiness Detail) | read live, never stored | One row per Monitoring Readiness check, with its status (`ok`, `warn`, `fail`, `unknown`) and the statement to run as the fix. Feeds the [Monitoring Readiness page](monitoring-pages.md#monitoring-readiness) | None |

## IBM Db2 Instance target {#instance-target}

An **IBM Db2 Instance** target monitors what belongs to the instance once per instance: memory, agents, the DBM CFG, the registry, the product level and the diagnostic log. The database targets keep every group they had, the instance-scope ones included. The full group table, properties and credentials are in [Instance targets](targets-and-properties.md#instance-targets).

**Groups shared with the database target**, with the same columns and thresholds: `Agent_Connection`, `Instance_Memory` (Warning 90 %, Critical 97 %), `Memory_Sets`, `FCM_Buffers`, `Latch_Waits`, `Diag_Log_File_Monitoring` (agents on the Db2 server only, `local` = 1), `License` and `CollectorStatus`. On the instance target, `Memory_Sets` lists every memory set of the instance and of each active database.

**Groups of its own:**

| Group | Interval | What it shows |
|---|---|---|
| `Response` | 5 min | Is the instance answering: `Status` 1 (up) or 0 (down), and a `Detail` in words. Critical when `Status` is not 1 |
| `Instance_Status` | 5 min | One row per member (`MON_GET_INSTANCE`): `db2_status`, start time, uptime, service level, local databases active now and connections since start. Warns when `db2_status` is `QUIESCE_PEND` or `QUIESCED` |
| `Active_Databases` | 15 min | The databases active on the instance now, with the memory each one's DATABASE memory set uses, has committed and has peaked at, in KB |
| `Db2InstanceConfiguration` | 24 hr | DBM CFG, registry, instance and product, system, and the DBM CFG security settings |

**How "up" is decided.** The instance is up when it accepts the connection and reports `ACTIVE`. It is also up when the connection database refuses at database level, because only a running instance can say "this database is an HADR standby", "quiesced", "not found" or "in a pending state". The other groups then record `DISABLED` in CollectorStatus with that reason. A wrong password, a missing privilege or a TLS problem is a metric collection error, never "down".

**Duplicate alerts.** Because the instance-scope groups collect on both target types, one breach opens an incident on the instance target and on each of its database targets. [Duplicate alerts](targets-and-properties.md#duplicate-alerts) gives the workaround.

## Related

- [Monitoring pages](monitoring-pages.md#51-ibm-db2-database-pages): the console pages these groups feed.
- [Alerts and templates](alerts-and-templates.md#default-thresholds): every shipped threshold, the monitoring templates and the incident rules.
- [Tuning thresholds](alerts-and-templates.md#tuning-thresholds): changing a value for one target or one key.
- [HADR monitoring](hadr-monitoring.md): the HADR groups, standby targets and client reroute.
- [Targets and properties](targets-and-properties.md#instance-targets): the instance target's properties, credentials and associations.
- [Compliance standards](compliance-standards.md#rules): the rules that read the configuration snapshot.
- [MCP server](mcp-server.md#collectorstatus): how an AI client uses CollectorStatus.
- [Troubleshooting](troubleshooting.md#empty-group): what to do when a group is empty.
- [Upgrade notes](upgrade-notes.md#renamed-groups): the groups metadata 4.7 renamed.
