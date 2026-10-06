---
title: Metrics reference
nav_order: 7
---

# Metrics reference

This chapter explains how to read the generated metrics reference.
**Topics:** 6.1 Where the reference is · 6.2 How to read a metric group · 6.3 Naming conventions
## 6.1 Where the reference is
The plug-in's metric documentation is generated from the plug-in's own target metadata, for the exact build you deploy, rather than written by hand — so it cannot drift from what the plug-in actually collects.

For this build it is the reference below, shipped alongside this guide. It covers all 119 metric groups: 107 on MySQL Database, 8 on MySQL Cluster and 4 on MySQL ClusterSet, each with its collection schedule, its columns, their display labels and units, and the default thresholds that ship. Where this guide and the reference differ on a column name, a unit or a threshold, the reference is authoritative ([1.4](index.md#14-beta-status)).

> **Note:** The reference accompanies this guide: in the repository as `user-guide-metrics-reference.md`, on the documentation site as `metrics-reference.md`. Either way, use the copy that matches the build you are running.

## 6.2 How to read a metric group
Every entry in the reference has the same shape, so once you can read one you can read all of them.

The heading gives the group's display name, its internal name in parentheses — the name EM CLI, thresholds and the metric browser use — and its collection schedule, for example *collected every 5 Min*. One sentence underneath says what the group collects and where the values come from. Then comes the column table:

| Column | What it tells you |
|---|---|
| **Column** | The column's internal name, in the form EM CLI and threshold commands take. A `(key)` marker means the column is part of the group's key, so the group returns one row per distinct key value — per channel, per member, per table, per digest — rather than a single row. A group with no key column returns exactly one row per collection. |
| **Label** | The display name shown in the console. Where the value's meaning is not obvious from the name, the label says it: what 1 means for a flag, which values a coded column takes, and the window a computed figure covers ([6.3](#63-naming-conventions)). |
| **Unit** | The unit Enterprise Manager labels the value with, for example `MICROSEC`, `BYTE`, `SECOND`, `HOURS`, `DAYS` or `PERCENTAGE`. Every column that has a real unit carries it. `NA` means the value has no unit: a plain count (a number of statements, rows or connections), a 0/1 flag, a coded setting, an identifier such as a port, a server ID or an error code, or a string. Enterprise Manager's MCP server shows these as `n/a`; read what such a column counts from its label. |
| **Warning** / **Critical** | The default threshold that ships for the column, with its operator. **A blank cell means no default threshold**, which is the normal case: 21 curated thresholds ship ([7.1](alerts-and-thresholds.md#71-default-thresholds)), and the reference also shows the three availability `Status` conditions, so 24 columns in the reference tables carry a default. A blank cell is not an omission and it does not stop you setting your own ([7.2](alerts-and-thresholds.md#72-changing-thresholds)). |

Groups marked **configuration snapshot** in their heading behave differently from the rest. They collect on a 24-hour schedule into Enterprise Manager's configuration history rather than into the metric tables, which is what makes a MySQL server's settings comparable over time and against other servers under **Enterprise → Configuration**, and what the compliance rules in [chapter 9](compliance-rules.md#compliance-standards) evaluate. They carry no thresholds and raise no alerts, and a `(key)` column in one of them means the snapshot holds several rows — one per account, for example — rather than one row of settings.

## 6.3 Naming conventions
Column names follow a few conventions consistently, so the name usually tells you what kind of number you are looking at.

| Suffix or pattern | Meaning |
|---|---|
| `_delta` | The difference since the previous collection. The server counter behind the column is cumulative since startup; the `_delta` column reports the activity in the interval instead, which is what a threshold can be set against. |
| `_pct` | A percentage, on a 0–100 scale. |
| `_rate` | A ratio expressed as a percentage — the buffer pool hit rates, for example, which the plug-in normalizes to percent at one decimal place. It is not a per-second figure. |
| `_per_sec` | A per-second rate. |
| `_us` | Microseconds. Statement and wait latencies are reported in microseconds throughout. |
| `d_` prefix | A per-interval delta on the wait and statement digest groups, the keyed equivalent of `_delta`. |
| `*Live` group | A real-time mirror of the configuration snapshot group of the same name — the same server variables, read on demand for the console's configuration side panels ([5.1](monitoring-pages.md#51-mysql-database-pages)) instead of on the daily configuration schedule. Same values, different freshness. |

**How labels state what a value means.** A label carries what its name cannot:

| Label wording | Meaning |
|---|---|
| `(0/1: 1 = ...)` | A flag. The label says what 1 means; 0 is the opposite. |
| `-1 = unknown` / `-1 = not assessed` | The collector could not measure the value, or no check ran. It is a value of its own and is never a `0`: a `0` is always a real measurement (a check that ran, or a count of none). A -1 is never a failure by itself, and the shipped conditions, at their default settings, do not fire on it. `dr_promotion_ready` spells out 1, 0 and -1 in full in its label. |
| `(ONLINE \| RECOVERING \| ...)` | A coded string column. The label lists the values it can take; a trailing `...` means the list is abbreviated to fit the console's 64-character label limit. |
| `(current)` | A gauge: the value as it is at the moment of the collection. |
| `(setting)` | A configured value (a server variable), not a measurement. It changes only when someone changes the configuration. |
| `(cumulative since server start)` | On a group name: every counter in the group is the running total since the server started (or since `FLUSH STATUS`), so a single value means little; compare two collections, or use the `_delta` and `_per_sec` columns where they exist. |
| `since prev. collection (~N min)` | A figure computed from the change since the previous collection, about N minutes earlier. After a missed cycle the window is longer than N minutes; it is never shorter. |
| `avg since prev. engine-status read, ~5 min` | An average per second (or per wait) taken from `SHOW ENGINE INNODB STATUS`, which the plug-in reads at most every 5 minutes and shares between groups. |
| `cumulative since member joined` | Group Replication counters that restart when the member rejoins the group. |

> **Note:** Metric descriptions are console-only. The `<Description>` text the plug-in ships on a metric group appears in the Enterprise Manager console, but Enterprise Manager's MCP server does not pass it to an AI agent: an agent asking about an incident, an event or a metric sees the label, the unit and the value, and none of the authored description text. This is why the label carries the meaning of a flag, a coded value or a window itself rather than leaving it to a description.

> **Note:** The replication metric group reports two different boolean vocabularies. `replica_io_running` returns `Yes` or `No`, while `replica_sql_running` returns `true` or `false`. The shipped thresholds match those forms exactly ([7.1](alerts-and-thresholds.md#71-default-thresholds)); a custom threshold, compliance rule or script that reads both columns must not assume a single format.

Generated from the plug-in's target metadata for build 24.1.9.10.0.
Each metric group lists its columns, display labels, units, and the default
warning/critical thresholds that ship (blank = no default threshold).
Configuration snapshots are RAW metrics collected for configuration history;
they do not carry thresholds. See the User Guide, chapter 6, for how to read this file.

## MySQL Database (`ip_mysql_database_beta`)

### Response (`Response`) — collected every 1 Min

Availability. EM derives the target's Up/Down state from the Status column; a Status below 1 raises the target-down event.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `Status` | Status (0/1: 1 = up, 0 = down) | NA |  | < 1 |

### Instance Info (`InstanceInfo`) — collected every 15 Min

Server version and installation directories (version, base directory, data directory, temp directory), read from global system variables.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `version` | Version | NA |  |  |
| `basedir` | Base Directory | NA |  |  |
| `datadir` | Data Directory | NA |  |  |
| `tmpdir` | Temp Directory | NA |  |  |

### Replication Source Config (`ReplicationSource`) — collected every 1 Hr

Source-role replication configuration — auto-increment offsets, GTID mode, and semi-sync source settings — read from the server's global variables. One row per server.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `auto_increment_increment` | Auto-Increment Step | NA |  |  |
| `auto_increment_offset` | Auto-Increment Start Offset | NA |  |  |
| `enforce_gtid_consistency` | Enforce GTID Consistency | NA |  |  |
| `gtid_executed` | GTID Executed | NA |  |  |
| `gtid_executed_compression_period` | GTID Compression Period (transactions) | NA |  |  |
| `gtid_mode` | GTID Mode | NA |  |  |
| `gtid_next` | GTID Next | NA |  |  |
| `gtid_owned` | GTID Owned | NA |  |  |
| `gtid_purged` | GTID Purged | NA |  |  |
| `server_uuid` | Server UUID | NA |  |  |
| `rpl_semi_sync_source_enabled` | Semi-Sync Source Enabled | NA |  |  |
| `rpl_semi_sync_source_timeout` | Semi-Sync Source Timeout (ms) | MILLISECONDS |  |  |
| `rpl_semi_sync_source_trace_level` | Semi-Sync Source Trace Level (bit mask) | NA |  |  |
| `rpl_semi_sync_source_wait_no_replica` | Semi-Sync Source Wait No Replica | NA |  |  |
| `server_id` | Server ID (this server) | NA |  |  |
| `source_verify_checksum` | Source Verify Checksum | NA |  |  |

### Replication Source Activity (`ReplicationSourceActivity`) — collected every 5 Min

Source-role replication activity — binary log cache usage, semi-sync source counters, and the current binary log file, position, and executed GTID set.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `binlog_cache_disk_use` | Binary Log Cache Disk Use | NA |  |  |
| `binlog_cache_use` | Binary Log Cache Use | NA |  |  |
| `rpl_semi_sync_source_clients` | Semi-Sync Source Clients | NA |  |  |
| `rpl_semi_sync_source_net_avg_wait_time` | Semi-Sync Source Net Avg Wait Time | MICROSEC |  |  |
| `rpl_semi_sync_source_net_waits` | Semi-Sync Source Net Waits | NA |  |  |
| `rpl_semi_sync_source_net_wait_time` | Semi-Sync Source Net Wait Time (total) | MICROSEC |  |  |
| `rpl_semi_sync_source_no_times` | Semi-Sync Source No Times | NA |  |  |
| `rpl_semi_sync_source_no_tx` | Semi-Sync Source No Transactions | NA |  |  |
| `rpl_semi_sync_source_status` | Semi-Sync Source Status (true \| false) | NA |  |  |
| `rpl_semi_sync_source_timefunc_failures` | Semi-Sync Source Timefunc Failures | NA |  |  |
| `rpl_semi_sync_source_tx_avg_wait_time` | Semi-Sync Source Tx Avg Wait Time | MICROSEC |  |  |
| `rpl_semi_sync_source_tx_waits` | Semi-Sync Source Tx Waits | NA |  |  |
| `rpl_semi_sync_source_tx_wait_time` | Semi-Sync Source Tx Wait Time (total) | MICROSEC |  |  |
| `rpl_semi_sync_source_wait_pos_backtraverse` | Semi-Sync Source Wait Pos Backtraverse | NA |  |  |
| `rpl_semi_sync_source_wait_sessions` | Semi-Sync Source Wait Sessions | NA |  |  |
| `rpl_semi_sync_source_yes_tx` | Semi-Sync Source Yes Transactions | NA |  |  |
| `com_show_binary_log_status` | SHOW BINARY LOG STATUS Count | NA |  |  |
| `com_show_replicas` | SHOW REPLICAS Count | NA |  |  |
| `file` | Binary Log File | NA |  |  |
| `position` | Binary Log Position (byte offset) | NA |  |  |
| `executed_gtid_set` | Executed GTID Set | NA |  |  |

### Replication Replica Config (`ReplicationReplica`) — collected every 1 Hr

Replica-role replication configuration for each replication channel — source connection details, SSL settings, filters, and relay log configuration.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `channel_name` (key) | Channel Name | NA |  |  |
| `auto_position` | Auto Position | NA |  |  |
| `connect_retry` | Connect Retry Interval (sec) | SECOND |  |  |
| `source_bind` | Source Bind | NA |  |  |
| `source_host` | Source Host | NA |  |  |
| `source_info_file` | Source Info File | NA |  |  |
| `source_port` | Source Port (TCP) | NA |  |  |
| `source_retry_count` | Source Retry Count (max attempts) | NA |  |  |
| `source_server_id` | Source Server ID (upstream server_id) | NA |  |  |
| `source_uuid` | Source UUID | NA |  |  |
| `source_ssl_allowed` | Source SSL Allowed | NA |  |  |
| `source_ssl_ca_file` | Source SSL CA File | NA |  |  |
| `source_ssl_ca_path` | Source SSL CA Path | NA |  |  |
| `source_ssl_cert` | Source SSL Cert | NA |  |  |
| `source_ssl_cipher` | Source SSL Cipher | NA |  |  |
| `source_ssl_crl` | Source SSL CRL | NA |  |  |
| `source_ssl_crl_path` | Source SSL CRL Path | NA |  |  |
| `source_ssl_key` | Source SSL Key | NA |  |  |
| `source_ssl_verify_server_cert` | Source SSL Verify Server Cert | NA |  |  |
| `source_user` | Source User | NA |  |  |
| `replicate_do_db` | Replicate Do DB | NA |  |  |
| `replicate_do_table` | Replicate Do Table | NA |  |  |
| `replicate_ignore_db` | Replicate Ignore DB | NA |  |  |
| `replicate_ignore_server_ids` | Replicate Ignore Server IDs | NA |  |  |
| `replicate_ignore_table` | Replicate Ignore Table | NA |  |  |
| `replicate_wild_do_table` | Replicate Wild Do Table | NA |  |  |
| `replicate_wild_ignore_table` | Replicate Wild Ignore Table | NA |  |  |
| `skip_counter` | Skip Counter (events to skip) | NA |  |  |
| `sql_delay` | SQL Delay (sec) | SECOND |  |  |
| `until_condition` | Until Condition | NA |  |  |
| `until_log_file` | Until Log File | NA |  |  |
| `until_log_pos` | Until Log Position (byte offset) | NA |  |  |
| `replicate_rewrite_db` | Replicate Rewrite DB | NA |  |  |
| `replica_allow_batching` | Replica Allow Batching | NA |  |  |
| `replica_checkpoint_group` | Replica Checkpoint Group (transactions) | NA |  |  |
| `replica_checkpoint_period` | Replica Checkpoint Period (ms) | MILLISECONDS |  |  |
| `replica_exec_mode` | Replica Exec Mode | NA |  |  |
| `gtid_mode` | GTID Mode | NA |  |  |
| `init_replica` | Init Replica | NA |  |  |
| `replica_load_tmpdir` | Replica Load Tmpdir | NA |  |  |
| `log_replica_updates` | Log Replica Updates | NA |  |  |
| `replica_max_allowed_packet` | Replica Max Allowed Packet (bytes) | BYTE |  |  |
| `max_relay_log_size` | Max Relay Log Size (bytes) | BYTE |  |  |
| `replica_net_timeout` | Replica Net Timeout (sec) | SECOND |  |  |
| `replica_parallel_type` | Replica Parallel Type (DATABASE \| LOGICAL_CLOCK) | NA |  |  |
| `replica_parallel_workers` | Replica Parallel Workers (threads) | NA |  |  |
| `replica_pending_jobs_size_max` | Replica Pending Jobs Max Size (bytes) | BYTE |  |  |
| `replica_preserve_commit_order` | Replica Preserve Commit Order | NA |  |  |
| `read_only` | Read Only | NA |  |  |
| `relay_log` | Relay Log | NA |  |  |
| `relay_log_basename` | Relay Log Basename | NA |  |  |
| `relay_log_index` | Relay Log Index | NA |  |  |
| `relay_log_info_file` | Relay Log Info File | NA |  |  |
| `relay_log_purge` | Relay Log Purge | NA |  |  |
| `relay_log_recovery` | Relay Log Recovery | NA |  |  |
| `relay_log_space_limit` | Relay Log Space Limit (bytes, 0 = no limit) | BYTE |  |  |
| `report_host` | Report Host | NA |  |  |
| `report_port` | Report Port (TCP) | NA |  |  |
| `report_user` | Report User | NA |  |  |
| `rpl_semi_sync_replica_enabled` | Semi-Sync Replica Enabled | NA |  |  |
| `rpl_semi_sync_replica_trace_level` | Semi-Sync Replica Trace Level (bit mask) | NA |  |  |
| `server_id` | Server ID (this server) | NA |  |  |
| `replica_skip_errors` | Replica Skip Errors | NA |  |  |
| `replica_sql_verify_checksum` | Replica SQL Verify Checksum | NA |  |  |
| `sync_source_info` | Sync Source Info (events) | NA |  |  |
| `sync_relay_log` | Sync Relay Log (events) | NA |  |  |
| `sync_relay_log_info` | Sync Relay Log Info (transactions) | NA |  |  |
| `replica_transaction_retries` | Replica Transaction Retries (max) | NA |  |  |
| `replica_type_conversions` | Replica Type Conversions | NA |  |  |

### Replication Replica Activity (`ReplicationReplicaActivity`) — collected every 5 Min

Replica-role replication activity per channel — I/O and SQL thread state, lag, and the most recent error. Note that replica_io_running reports Yes/No while replica_sql_running reports true/false; write any custom rule against both columns accordingly.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `channel_name` (key) | Channel Name | NA |  |  |
| `replica_io_state` | Replica IO State | NA |  |  |
| `source_log_file` | Source Log File | NA |  |  |
| `read_source_log_pos` | Read Source Log Position | NA |  |  |
| `relay_log_file` | Relay Log File | NA |  |  |
| `relay_log_pos` | Relay Log Position | NA |  |  |
| `relay_source_log_file` | Relay Source Log File | NA |  |  |
| `replica_io_running` | Replica IO Running (Yes \| No \| Connecting) | NA |  | = No |
| `replica_sql_running` | Replica SQL Running (true \| false) | NA |  | = false |
| `last_errno` | Last Error Number (0 = no error) | NA |  |  |
| `last_error` | Last Error | NA |  |  |
| `relay_log_space` | Relay Log Space (bytes) | BYTE |  |  |
| `last_io_errno` | Last IO Error Number (0 = no error) | NA |  |  |
| `last_io_error` | Last IO Error | NA |  |  |
| `last_sql_errno` | Last SQL Error Number (0 = no error) | NA |  |  |
| `last_sql_error` | Last SQL Error | NA |  |  |
| `skip_counter` | Skip Counter (events to skip) | NA |  |  |
| `exec_source_log_pos` | Exec Source Log Position | NA |  |  |
| `seconds_behind_source` | Seconds Behind Source (valid if Lag Measured = 1) | SECOND | > 30 | > 300 |
| `sql_remaining_delay` | SQL Remaining Delay (sec) | SECOND |  |  |
| `replica_sql_running_state` | Replica SQL Running State | NA |  |  |
| `retrieved_gtid_set` | Retrieved GTID Set | NA |  |  |
| `executed_gtid_set` | Executed GTID Set | NA |  |  |
| `source_host` | Source Host | NA |  |  |
| `com_change_replication_source` | CHANGE REPLICATION SOURCE Count | NA |  |  |
| `com_replica_start` | START REPLICA Count | NA |  |  |
| `com_replica_stop` | STOP REPLICA Count | NA |  |  |
| `com_show_replica_status` | SHOW REPLICA STATUS Count | NA |  |  |
| `rpl_semi_sync_replica_status` | Semi-Sync Replica Status (true \| false) | NA |  |  |
| `replica_heartbeat_period` | Replica Heartbeat Period (sec) | SECOND |  |  |
| `replica_open_temp_tables` | Open Temporary Tables (replica SQL thread) | NA |  |  |
| `replica_received_heartbeats` | Heartbeats Received (cumulative) | NA |  |  |
| `replica_retried_transactions` | Transactions Retried (cumulative) | NA |  |  |
| `replica_running` | Replica Running (true \| false) | NA |  |  |
| `relay_log_purge` | Relay Log Purge (true \| false) | NA |  |  |
| `lag_measured` | Lag Measured (0/1: 1 = Seconds Behind Source is real) | NA |  |  |

### Log IO Latency (`LogIOLatency`) — collected every 5 Min

Binary log I/O volume and latency, aggregated from performance_schema.file_summary_by_event_name for binlog file events.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `log_bytes_written` | Log Bytes Written (cumulative bytes) | BYTE |  |  |
| `file_io_latency` | File IO Latency (cumulative ms) | MILLISECONDS |  |  |

### Replication Connection Status (`ReplicationConnStatus`) — collected every 5 Min

Per-channel replication connection heartbeat status, from performance_schema.replication_connection_status.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `channel_name` (key) | Channel Name | NA |  |  |
| `count_received_heartbeats` | Received Heartbeats (cumulative) | NA |  |  |
| `last_heartbeat_timestamp` | Last Heartbeat Timestamp | NA |  |  |

### Replication Connection Config (`ReplicationConnectionConfig`) — collected every 1 Hr

Per-channel replication connection configuration — auto-positioning, retry interval and count, and heartbeat interval — from performance_schema.replication_connection_configuration.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `channel_name` (key) | Channel Name | NA |  |  |
| `auto_positioning_enabled` | Auto Positioning Enabled | NA |  |  |
| `connection_retry_interval` | Connection Retry Interval (sec) | SECOND |  |  |
| `connection_retry_count` | Connection Retry Count (max attempts) | NA |  |  |
| `heartbeat_interval` | Heartbeat Interval (sec) | SECOND |  |  |
| `bound_network_interface` | Bound Network Interface | NA |  |  |
| `source_info_storage` | Source Info Storage | NA |  |  |

### Replication By Coordinator (`ReplicationByCoordinator`) — collected every 5 Min

Per-channel applier coordinator thread state and the most recent applier error, from performance_schema.replication_applier_status_by_coordinator.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `channel_name` (key) | Channel Name | NA |  |  |
| `thread_id` | Thread ID | NA |  |  |
| `service_state` | Service State (ON \| OFF; OFF is normal on a GR SECONDARY) | NA |  |  |
| `last_error_number` | Last Error Number (0 = no error) | NA |  |  |
| `last_error_timestamp` | Last Error Timestamp | NA |  |  |

### Replication By Worker (`ReplicationByWorker`) — collected every 5 Min

Per-channel, per-worker applier thread state and the most recent applier error, from performance_schema.replication_applier_status_by_worker.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `channel_name` (key) | Channel Name | NA |  |  |
| `worker_id` (key) | Worker ID | NA |  |  |
| `thread_id` | Thread ID | NA |  |  |
| `service_state` | Service State (ON \| OFF; OFF is normal on a GR SECONDARY) | NA |  |  |
| `last_error_message` | Last Error Message | NA |  |  |
| `last_error_number` | Last Error Number (0 = no error) | NA |  |  |
| `last_applied_transaction` | Last Applied Transaction | NA |  |  |

### InnoDB Activity (cumulative since server start) (`InnodbActivity`) — collected every 5 Min

InnoDB engine activity counters — buffer pool traffic, data file I/O, log I/O, double-write, and row operations — from the server's InnoDB status counters.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_buffer_pool_bytes_data` | Buffer Pool Bytes Data (current) | BYTE |  |  |
| `innodb_buffer_pool_bytes_dirty` | Buffer Pool Bytes Dirty (current) | BYTE |  |  |
| `innodb_buffer_pool_dump_status` | Buffer Pool Dump Status | NA |  |  |
| `innodb_buffer_pool_load_status` | Buffer Pool Load Status | NA |  |  |
| `innodb_buffer_pool_pages_data` | Buffer Pool Pages Data (current) | NA |  |  |
| `innodb_buffer_pool_pages_dirty` | Buffer Pool Pages Dirty (current) | NA |  |  |
| `innodb_buffer_pool_pages_flushed` | Buffer Pool Pages Flushed | NA |  |  |
| `innodb_buffer_pool_pages_free` | Buffer Pool Pages Free (current) | NA |  |  |
| `innodb_buffer_pool_pages_misc` | Buffer Pool Pages Misc (current) | NA |  |  |
| `innodb_buffer_pool_pages_total` | Buffer Pool Pages Total (current) | NA |  |  |
| `innodb_buffer_pool_read_ahead` | Buffer Pool Read Ahead | NA |  |  |
| `innodb_buffer_pool_read_ahead_evicted` | Buffer Pool Read Ahead Evicted | NA |  |  |
| `innodb_buffer_pool_read_requests` | Buffer Pool Read Requests | NA |  |  |
| `innodb_buffer_pool_reads` | Buffer Pool Reads | NA |  |  |
| `innodb_buffer_pool_resize_status` | Buffer Pool Resize Status | NA |  |  |
| `innodb_buffer_pool_wait_free` | Buffer Pool Wait Free | NA |  |  |
| `innodb_buffer_pool_write_requests` | Buffer Pool Write Requests | NA |  |  |
| `innodb_data_fsyncs` | Data Fsyncs | NA |  |  |
| `innodb_data_pending_fsyncs` | Data Pending Fsyncs (current) | NA |  |  |
| `innodb_data_pending_reads` | Data Pending Reads (current) | NA |  |  |
| `innodb_data_pending_writes` | Data Pending Writes (current) | NA |  |  |
| `innodb_data_read` | Data Read | BYTE |  |  |
| `innodb_data_reads` | Data Reads | NA |  |  |
| `innodb_data_writes` | Data Writes | NA |  |  |
| `innodb_data_written` | Data Written | BYTE |  |  |
| `innodb_dblwr_pages_written` | Dblwr Pages Written | NA |  |  |
| `innodb_dblwr_writes` | Dblwr Writes | NA |  |  |
| `innodb_log_waits` | Log Waits | NA |  |  |
| `innodb_log_write_requests` | Log Write Requests | NA |  |  |
| `innodb_log_writes` | Log Writes | NA |  |  |
| `innodb_os_log_fsyncs` | OS Log Fsyncs | NA |  |  |
| `innodb_os_log_pending_fsyncs` | OS Log Pending Fsyncs (current) | NA |  |  |
| `innodb_os_log_pending_writes` | OS Log Pending Writes (current) | NA |  |  |
| `innodb_os_log_written` | OS Log Written | BYTE |  |  |
| `innodb_pages_created` | Pages Created | NA |  |  |
| `innodb_page_size` | Page Size (setting) | BYTE |  |  |
| `innodb_pages_read` | Pages Read | NA |  |  |
| `innodb_pages_written` | Pages Written | NA |  |  |
| `innodb_row_lock_current_waits` | Row Lock Current Waits (current) | NA |  |  |
| `innodb_row_lock_time` | Row Lock Time | MILLISECONDS |  |  |
| `innodb_row_lock_time_avg` | Row Lock Time Avg (ms) | MILLISECONDS |  |  |
| `innodb_row_lock_time_max` | Row Lock Time Max (ms, peak) | MILLISECONDS |  |  |
| `innodb_row_lock_waits` | Row Lock Waits | NA |  |  |
| `innodb_rows_deleted` | Rows Deleted | NA |  |  |
| `innodb_rows_inserted` | Rows Inserted | NA |  |  |
| `innodb_rows_read` | Rows Read | NA |  |  |
| `innodb_rows_updated` | Rows Updated | NA |  |  |
| `innodb_truncated_status_writes` | Truncated Status Writes | NA |  |  |
| `uptime` | Uptime | SECOND |  |  |

### InnoDB Buffer Pool (cumulative since server start) (`InnodbBufferPool`) — collected every 5 Min

InnoDB buffer pool sizing and effectiveness — hit rates and page allocation from INFORMATION_SCHEMA.INNODB_BUFFER_POOL_STATS.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_bp_total_alloc` | BP Total Alloc (current) | BYTE |  |  |
| `innodb_bp_dictionary_alloc` | BP Dictionary Alloc (current) | BYTE |  |  |
| `innodb_bp_size` | BP Size (pages, current) | NA |  |  |
| `innodb_bp_free_buffers` | BP Free Buffers (current) | NA |  |  |
| `innodb_bp_db_pages` | BP Db Pages (current) | NA |  |  |
| `innodb_bp_old_db_pages` | BP Old Db Pages (current) | NA |  |  |
| `innodb_bp_modified_pages` | BP Modified Pages (current) | NA |  |  |
| `innodb_bp_pending_pages` | BP Pending Pages (current) | NA |  |  |
| `innodb_bp_pending_writes_lru` | BP Pending Writes LRU (current) | NA |  |  |
| `innodb_bp_pending_writes_flush_list` | BP Pending Writes Flush List (current) | NA |  |  |
| `innodb_bp_pending_writes_single_page` | BP Pending Writes Single Page (current) | NA |  |  |
| `innodb_bp_pages_young` | BP Pages Young | NA |  |  |
| `innodb_bp_pages_not_young` | BP Pages Not Young | NA |  |  |
| `innodb_bp_pages_young_per_sec` | BP Pages Young/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_pages_not_young_per_sec` | BP Not Young/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_pages_read` | BP Pages Read | NA |  |  |
| `innodb_bp_pages_created` | BP Pages Created | NA |  |  |
| `innodb_bp_pages_written` | BP Pages Written | NA |  |  |
| `innodb_bp_reads_per_sec` | BP Reads/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_created_per_sec` | BP Created/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_written_per_sec` | BP Written/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_hit_rate` | BP Hit Rate (%, last ~5 min) | PERCENTAGE | < 95 | < 90 |
| `innodb_bp_young_hit_rate` | BP Young Hit Rate (%, last ~5 min) | PERCENTAGE |  |  |
| `innodb_bp_not_young_hit_rate` | BP Not Young Hit Rate (%, last ~5 min) | PERCENTAGE |  |  |
| `innodb_bp_pages_read_ahead_per_sec` | BP Read Ahead/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_pages_evicted_no_access_per_sec` | BP Evicted Unused/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_pages_random_read_ahead_per_sec` | BP Random R-Ahead/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_bp_lru_len` | BP LRU Len (current) | NA |  |  |
| `innodb_bp_unzip_lru_len` | BP Unzip LRU Len (current) | NA |  |  |
| `innodb_bp_io_sum_pages` | BP IO Sum Pages (last ~50 s) | NA |  |  |
| `innodb_bp_io_cur_pages` | BP IO Cur Pages (current) | NA |  |  |
| `innodb_bp_io_unzip_sum_pages` | BP IO Unzip Sum Pages (last ~50 s) | NA |  |  |
| `innodb_bp_io_unzip_cur_pages` | BP IO Unzip Cur Pages (current) | NA |  |  |
| `compress_seconds` | Compress Seconds | SECOND |  |  |
| `uncompress_seconds` | Uncompress Seconds | SECOND |  |  |

### InnoDB Log (cumulative since server start) (`InnodbLog`) — collected every 5 Min

InnoDB redo log position and capacity — sequence, flushed, and checkpoint LSNs plus log capacity used — parsed from the InnoDB engine status output.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_log_sequence_lsn` | Log Sequence LSN | NA |  |  |
| `innodb_log_flushed_lsn` | Log Flushed LSN | NA |  |  |
| `innodb_log_pages_flushed_lsn` | Log Pages Flushed LSN | NA |  |  |
| `innodb_log_checkpoint_lsn` | Log Checkpoint LSN | NA |  |  |
| `innodb_log_capacity` | Log Capacity (current) | BYTE |  |  |
| `innodb_log_capacity_used` | Log Capacity Used (checkpoint age, current) | BYTE |  |  |
| `innodb_log_io_total` | Log IO Total | NA |  |  |
| `innodb_log_io_per_sec` | Log Io/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |

### InnoDB Transactions (`InnodbTransaction`) — collected every 5 Min

InnoDB transaction state — counts of running, lock-waiting, committing, and rolling-back transactions, plus row-lock memory and wait totals — combining the InnoDB engine status output with INFORMATION_SCHEMA.INNODB_TRX.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_trx_id_counter_str` | Trx Id Counter Str | NA |  |  |
| `innodb_trx_purge_done` | Trx Purge Done | NA |  |  |
| `innodb_trx_history_list_length` | Trx History List Length (current) | NA | > 100000 | > 1000000 |
| `running_count` | Running Count (current) | NA |  |  |
| `lock_wait_count` | Lock Wait Count (current) | NA |  |  |
| `committing_count` | Committing Count (current) | NA |  |  |
| `rolling_back_count` | Rolling Back Count (current) | NA |  |  |
| `lock_memory_bytes_total` | Lock Memory Bytes Total (current) | BYTE |  |  |
| `rows_locked_total` | Rows Locked Total (current) | NA |  |  |
| `rows_modified_total` | Rows Modified Total (current) | NA |  |  |
| `row_locks_current_waits` | Row Locks Current Waits (current) | NA |  |  |

### InnoDB I/O (cumulative since server start) (`InnodbIO`) — collected every 5 Min

InnoDB file I/O activity — OS-level reads, writes, fsyncs, and pending operations — parsed from the InnoDB engine status output.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_io_os_file_reads` | IO OS File Reads | NA |  |  |
| `innodb_io_os_file_writes` | IO OS File Writes | NA |  |  |
| `innodb_io_os_file_fsyncs` | IO OS File Fsyncs | NA |  |  |
| `innodb_io_pending_reads` | IO Pending Reads (current) | NA |  |  |
| `innodb_io_pending_writes` | IO Pending Writes (current) | NA |  |  |
| `innodb_io_pending_flush_log` | IO Pending Flush Log (current) | NA |  |  |
| `innodb_io_pending_flush_bp` | IO Pending Flush BP (current) | NA |  |  |
| `innodb_bytes_per_read` | Bytes Per Read (avg since prev. engine-status read, ~5 min) | BYTE |  |  |
| `innodb_reads_per_sec` | Reads/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_writes_per_sec` | Writes/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_io_syncs_per_sec` | IO Syncs/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_num_open_files` | Num Open Files (current) | NA |  |  |

### InnoDB Row Operations (cumulative since server start) (`InnodbRow`) — collected every 5 Min

InnoDB row operation counts and rates — inserts, updates, deletes, and reads — parsed from the InnoDB engine status output.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_row_queries_inside` | Row Queries Inside (current) | NA |  |  |
| `innodb_row_queries_queue` | Row Queries Queue (current) | NA |  |  |
| `innodb_rows_inserted` | Rows Inserted | NA |  |  |
| `innodb_rows_updated` | Rows Updated | NA |  |  |
| `innodb_rows_deleted` | Rows Deleted | NA |  |  |
| `innodb_rows_read` | Rows Read | NA |  |  |
| `innodb_rows_inserted_per_sec` | Rows Inserted/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_rows_updated_per_sec` | Rows Updated/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_rows_deleted_per_sec` | Rows Deleted/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_rows_read_per_sec` | Rows Read/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |

### InnoDB Insert Buffer (cumulative since server start) (`InnodbInsertBuffer`) — collected every 5 Min

InnoDB change buffer (insert buffer) size and merge/discard activity, parsed from the InnoDB engine status output.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_ibuf_size` | Ibuf Size (pages, current) | NA |  |  |
| `innodb_ibuf_free_list_len` | Ibuf Free List Len (pages, current) | NA |  |  |
| `innodb_ibuf_seg_size` | Ibuf Seg Size (pages, current) | NA |  |  |
| `innodb_cbuf_insert_merges` | Cbuf Insert Merges | NA |  |  |
| `innodb_cbuf_delete_mark_merges` | Cbuf Delete Mark Merges | NA |  |  |
| `innodb_cbuf_delete_merges` | Cbuf Delete Merges | NA |  |  |
| `innodb_cbuf_insert_discarded` | Cbuf Insert Discarded | NA |  |  |
| `innodb_cbuf_delete_mark_discarded` | Cbuf Delete Mark Discarded | NA |  |  |
| `innodb_cbuf_delete_discarded` | Cbuf Delete Discarded | NA |  |  |

### InnoDB Adaptive Hash (`InnodbAdaptiveHash`) — collected every 5 Min

InnoDB adaptive hash index size and search rates, parsed from the InnoDB engine status output.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_hash_table_size` | Hash Table Size (cells, current) | NA |  |  |
| `innodb_hash_node_heap` | Hash Node Heap (buffers, current) | NA |  |  |
| `innodb_hash_searches_per_sec` | Hash Searches/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |
| `innodb_non_hash_searches_per_sec` | Non Hash Searches/s (avg since prev. engine-status read, ~5 min) | SECOND |  |  |

### InnoDB Threads (cumulative since server start) (`InnodbThread`) — collected every 5 Min

InnoDB background (main) thread loop counters and current state, parsed from the InnoDB engine status output.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_main_thd_loops_srv_active` | Main Thd Loops Srv Active | NA |  |  |
| `innodb_main_thd_loops_srv_shutdown` | Main Thd Loops Srv Shutdown | NA |  |  |
| `innodb_main_thd_loops_srv_idle` | Main Thd Loops Srv Idle | NA |  |  |
| `innodb_main_thd_log_flush_writes` | Main Thd Log Flush Writes | NA |  |  |
| `innodb_row_state` | Row State | NA |  |  |

### InnoDB Semaphores (cumulative since server start) (`InnodbSemaphore`) — collected every 5 Min

InnoDB internal synchronization activity — mutex and rw-lock spin, rounds, and OS wait counts — parsed from the InnoDB engine status output.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `innodb_sem_os_reservation_count` | Sem OS Reservation Count | NA |  |  |
| `innodb_sem_os_signal_count` | Sem OS Signal Count | NA |  |  |
| `innodb_sem_shared_spins` | Sem Shared Spins | NA |  |  |
| `innodb_sem_shared_rounds` | Sem Shared Rounds | NA |  |  |
| `innodb_sem_shared_os_waits` | Sem Shared OS Waits | NA |  |  |
| `innodb_sem_rw_excl_spins` | Sem RW Excl Spins | NA |  |  |
| `innodb_sem_rw_excl_rounds` | Sem RW Excl Rounds | NA |  |  |
| `innodb_sem_rw_excl_os_waits` | Sem RW Excl OS Waits | NA |  |  |
| `innodb_sem_rw_sx_spins` | Sem RW SX Spins | NA |  |  |
| `innodb_sem_rw_sx_rounds` | Sem RW SX Rounds | NA |  |  |
| `innodb_sem_rw_sx_os_waits` | Sem RW SX OS Waits | NA |  |  |
| `innodb_sem_spins_per_wait_rw_shared` | Spins Per Wait RW Shared (avg since prev. engine-status read) | NA |  |  |
| `innodb_sem_spins_per_wait_rw_excl` | Spins Per Wait RW Excl (avg since prev. engine-status read) | NA |  |  |
| `innodb_sem_spins_per_wait_rw_sx` | Spins Per Wait RW SX (avg since prev. engine-status read) | NA |  |  |

### Admin Statement Activity (cumulative since server start) (`AdminStatementActivity`) — collected every 5 Min

Counts of the server's AdminStatementActivity statements, read as raw SHOW GLOBAL STATUS counters (cumulative since server start; a restart or FLUSH STATUS resets them), so chart a rate or a difference between readings to see activity in an interval.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `com_admin_commands` | Com Admin Commands | NA |  |  |
| `com_analyze` | Com Analyze | NA |  |  |
| `com_assign_to_keycache` | Com Assign To Keycache | NA |  |  |
| `com_binlog` | Com Binlog | NA |  |  |
| `com_change_replication_source` | Com Change Replication Source | NA |  |  |
| `com_check` | Com Check | NA |  |  |
| `com_checksum` | Com Checksum | NA |  |  |
| `com_flush` | Com Flush | NA |  |  |
| `com_install_plugin` | Com Install Plugin | NA |  |  |
| `com_kill` | Com Kill | NA |  |  |
| `com_optimize` | Com Optimize | NA |  |  |
| `com_preload_keys` | Com Preload Keys | NA |  |  |
| `com_purge` | Com Purge | NA |  |  |
| `com_purge_before_date` | Com Purge Before Date | NA |  |  |
| `com_repair` | Com Repair | NA |  |  |
| `com_replica_start` | Com Replica Start | NA |  |  |
| `com_replica_stop` | Com Replica Stop | NA |  |  |
| `com_uninstall_plugin` | Com Uninstall Plugin | NA |  |  |

### DDL Statement Activity (cumulative since server start) (`DdlStatementActivity`) — collected every 5 Min

Counts of the server's DdlStatementActivity statements, read as raw SHOW GLOBAL STATUS counters (cumulative since server start; a restart or FLUSH STATUS resets them), so chart a rate or a difference between readings to see activity in an interval.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `com_alter_db` | Com Alter Db | NA |  |  |
| `com_alter_event` | Com Alter Event | NA |  |  |
| `com_alter_function` | Com Alter Function | NA |  |  |
| `com_alter_procedure` | Com Alter Procedure | NA |  |  |
| `com_alter_server` | Com Alter Server | NA |  |  |
| `com_alter_table` | Com Alter Table | NA |  |  |
| `com_alter_tablespace` | Com Alter Tablespace | NA |  |  |
| `com_create_db` | Com Create Db | NA |  |  |
| `com_create_event` | Com Create Event | NA |  |  |
| `com_create_function` | Com Create Function | NA |  |  |
| `com_create_index` | Com Create Index | NA |  |  |
| `com_create_procedure` | Com Create Procedure | NA |  |  |
| `com_create_server` | Com Create Server | NA |  |  |
| `com_create_table` | Com Create Table | NA |  |  |
| `com_create_trigger` | Com Create Trigger | NA |  |  |
| `com_create_udf` | Com Create Udf | NA |  |  |
| `com_create_user` | Com Create User | NA |  |  |
| `com_create_view` | Com Create View | NA |  |  |
| `com_drop_db` | Com Drop Db | NA |  |  |
| `com_drop_event` | Com Drop Event | NA |  |  |
| `com_drop_function` | Com Drop Function | NA |  |  |
| `com_drop_index` | Com Drop Index | NA |  |  |
| `com_drop_procedure` | Com Drop Procedure | NA |  |  |
| `com_drop_server` | Com Drop Server | NA |  |  |
| `com_drop_table` | Com Drop Table | NA |  |  |
| `com_drop_trigger` | Com Drop Trigger | NA |  |  |
| `com_drop_user` | Com Drop User | NA |  |  |
| `com_drop_view` | Com Drop View | NA |  |  |
| `com_grant` | Com Grant | NA |  |  |
| `com_rename_table` | Com Rename Table | NA |  |  |
| `com_rename_user` | Com Rename User | NA |  |  |
| `com_truncate` | Com Truncate | NA |  |  |

### DML Statement Activity (cumulative since server start) (`DmlStatementActivity`) — collected every 5 Min

Counts of the server's DmlStatementActivity statements, read as raw SHOW GLOBAL STATUS counters (cumulative since server start; a restart or FLUSH STATUS resets them), so chart a rate or a difference between readings to see activity in an interval.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `com_call_procedure` | Com Call Procedure | NA |  |  |
| `com_change_db` | Com Change Db | NA |  |  |
| `com_dealloc_sql` | Com Dealloc Sql | NA |  |  |
| `com_delete` | Com Delete | NA |  |  |
| `com_delete_multi` | Com Delete Multi | NA |  |  |
| `com_do` | Com Do | NA |  |  |
| `com_empty_query` | Com Empty Query | NA |  |  |
| `com_execute_sql` | Com Execute Sql | NA |  |  |
| `com_ha_close` | Com HA Close | NA |  |  |
| `com_ha_open` | Com HA Open | NA |  |  |
| `com_ha_read` | Com HA Read | NA |  |  |
| `com_help` | Com Help | NA |  |  |
| `com_insert` | Com Insert | NA |  |  |
| `com_insert_select` | Com Insert Select | NA |  |  |
| `com_load` | Com Load | NA |  |  |
| `com_lock_tables` | Com Lock Tables | NA |  |  |
| `com_prepare_sql` | Com Prepare Sql | NA |  |  |
| `com_replace` | Com Replace | NA |  |  |
| `com_replace_select` | Com Replace Select | NA |  |  |
| `com_reset` | Com Reset | NA |  |  |
| `com_resignal` | Com Resignal | NA |  |  |
| `com_select` | Com Select | NA |  |  |
| `com_set_option` | Com Set Option | NA |  |  |
| `com_signal` | Com Signal | NA |  |  |
| `com_stmt_close` | Com Stmt Close | NA |  |  |
| `com_stmt_execute` | Com Stmt Execute | NA |  |  |
| `com_stmt_fetch` | Com Stmt Fetch | NA |  |  |
| `com_stmt_prepare` | Com Stmt Prepare | NA |  |  |
| `com_stmt_reprepare` | Com Stmt Reprepare | NA |  |  |
| `com_stmt_reset` | Com Stmt Reset | NA |  |  |
| `com_stmt_send_long_data` | Com Stmt Send Long Data | NA |  |  |
| `com_unlock_tables` | Com Unlock Tables | NA |  |  |
| `com_update` | Com Update | NA |  |  |
| `com_update_multi` | Com Update Multi | NA |  |  |

### Show Statement Activity (cumulative since server start) (`ShowStatementActivity`) — collected every 5 Min

Counts of the server's ShowStatementActivity statements, read as raw SHOW GLOBAL STATUS counters (cumulative since server start; a restart or FLUSH STATUS resets them), so chart a rate or a difference between readings to see activity in an interval.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `com_show_binlog_events` | Com Show Binlog Events | NA |  |  |
| `com_show_binlogs` | Com Show Binlogs | NA |  |  |
| `com_show_charsets` | Com Show Charsets | NA |  |  |
| `com_show_collations` | Com Show Collations | NA |  |  |
| `com_show_create_db` | Com Show Create Db | NA |  |  |
| `com_show_create_event` | Com Show Create Event | NA |  |  |
| `com_show_create_func` | Com Show Create Func | NA |  |  |
| `com_show_create_proc` | Com Show Create Proc | NA |  |  |
| `com_show_create_table` | Com Show Create Table | NA |  |  |
| `com_show_create_trigger` | Com Show Create Trigger | NA |  |  |
| `com_show_databases` | Com Show Databases | NA |  |  |
| `com_show_engine_logs` | Com Show Engine Logs | NA |  |  |
| `com_show_engine_mutex` | Com Show Engine Mutex | NA |  |  |
| `com_show_engine_status` | Com Show Engine Status | NA |  |  |
| `com_show_errors` | Com Show Errors | NA |  |  |
| `com_show_events` | Com Show Events | NA |  |  |
| `com_show_fields` | Com Show Fields | NA |  |  |
| `com_show_function_code` | Com Show Function Code | NA |  |  |
| `com_show_function_status` | Com Show Function Status | NA |  |  |
| `com_show_grants` | Com Show Grants | NA |  |  |
| `com_show_keys` | Com Show Keys | NA |  |  |
| `com_show_binary_log_status` | Com Show Binary Log Status | NA |  |  |
| `com_show_open_tables` | Com Show Open Tables | NA |  |  |
| `com_show_plugins` | Com Show Plugins | NA |  |  |
| `com_show_privileges` | Com Show Privileges | NA |  |  |
| `com_show_procedure_code` | Com Show Procedure Code | NA |  |  |
| `com_show_procedure_status` | Com Show Procedure Status | NA |  |  |
| `com_show_processlist` | Com Show Processlist | NA |  |  |
| `com_show_profile` | Com Show Profile | NA |  |  |
| `com_show_profiles` | Com Show Profiles | NA |  |  |
| `com_show_relaylog_events` | Com Show Relaylog Events | NA |  |  |
| `com_show_replicas` | Com Show Replicas | NA |  |  |
| `com_show_replica_status` | Com Show Replica Status | NA |  |  |
| `com_show_status` | Com Show Status | NA |  |  |
| `com_show_storage_engines` | Com Show Storage Engines | NA |  |  |
| `com_show_tables` | Com Show Tables | NA |  |  |
| `com_show_table_status` | Com Show Table Status | NA |  |  |
| `com_show_triggers` | Com Show Triggers | NA |  |  |
| `com_show_variables` | Com Show Variables | NA |  |  |
| `com_show_warnings` | Com Show Warnings | NA |  |  |

### Transaction Statement Activity (cumulative since server start) (`TransactionStatementActivity`) — collected every 5 Min

Counts of the server's TransactionStatementActivity statements, read as raw SHOW GLOBAL STATUS counters (cumulative since server start; a restart or FLUSH STATUS resets them), so chart a rate or a difference between readings to see activity in an interval.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `com_begin` | Com Begin | NA |  |  |
| `com_commit` | Com Commit | NA |  |  |
| `com_release_savepoint` | Com Release Savepoint | NA |  |  |
| `com_rollback` | Com Rollback | NA |  |  |
| `com_rollback_to_savepoint` | Com Rollback To Savepoint | NA |  |  |
| `com_savepoint` | Com Savepoint | NA |  |  |
| `com_xa_commit` | Com XA Commit | NA |  |  |
| `com_xa_end` | Com XA End | NA |  |  |
| `com_xa_prepare` | Com XA Prepare | NA |  |  |
| `com_xa_recover` | Com XA Recover | NA |  |  |
| `com_xa_rollback` | Com XA Rollback | NA |  |  |
| `com_xa_start` | Com XA Start | NA |  |  |

### Handler Activity (cumulative since server start) (`HandlerActivity`) — collected every 5 Min

Storage engine handler call counts — reads, writes, commits, and rollbacks — from the server's Handler_* status counters.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `handler_commit` | Handler Commit | NA |  |  |
| `handler_delete` | Handler Delete | NA |  |  |
| `handler_discover` | Handler Discover | NA |  |  |
| `handler_external_lock` | Handler External Lock | NA |  |  |
| `handler_mrr_init` | Handler Mrr Init | NA |  |  |
| `handler_prepare` | Handler Prepare | NA |  |  |
| `handler_read_first` | Handler Read First | NA |  |  |
| `handler_read_key` | Handler Read Key | NA |  |  |
| `handler_read_last` | Handler Read Last | NA |  |  |
| `handler_read_next` | Handler Read Next | NA |  |  |
| `handler_read_prev` | Handler Read Prev | NA |  |  |
| `handler_read_rnd` | Handler Read Rnd | NA |  |  |
| `handler_read_rnd_next` | Handler Read Rnd Next | NA |  |  |
| `handler_rollback` | Handler Rollback | NA |  |  |
| `handler_savepoint` | Handler Savepoint | NA |  |  |
| `handler_savepoint_rollback` | Handler Savepoint Rollback | NA |  |  |
| `handler_update` | Handler Update | NA |  |  |
| `handler_write` | Handler Write | NA |  |  |
| `uptime` | Uptime | SECOND |  |  |

### Instance Activity (cumulative since server start) (`InstanceActivity`) — collected every 5 Min

General server activity counters — queries served, open files, prepared statements, and uptime — from the server's status counters.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `acl_cache_items_count` | Acl Cache Items Count (current) | NA |  |  |
| `flush_commands` | Flush Commands | NA |  |  |
| `opened_files` | Opened Files | NA |  |  |
| `open_files` | Open Files (current) | NA |  |  |
| `open_streams` | Open Streams (current) | NA |  |  |
| `prepared_stmt_count` | Prepared Stmt Count (current) | NA |  |  |
| `queries` | Queries | NA |  |  |
| `questions` | Questions | NA |  |  |
| `uptime` | Uptime | SECOND |  |  |
| `uptime_since_flush_status` | Uptime Since Flush Status (seconds) | SECOND |  |  |

### XA Activity (cumulative since server start) (`XaActivity`) — collected every 5 Min

XA / two-phase-commit transaction coordinator log counters — page size, pages used, and page waits.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `tc_log_max_pages_used` | Tc Log Max Pages Used (peak) | NA |  |  |
| `tc_log_page_size` | Tc Log Page Size (setting) | BYTE |  |  |
| `tc_log_page_waits` | Tc Log Page Waits | NA |  |  |

### Connection Activity (cumulative since server start) (`ConnectionActivity`) — collected every 5 Min

Connection-level activity counters — aborted clients and connects, bytes transferred, and thread caching — from the server's status counters; aborted_connects_delta reports the count as a delta between collections.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `aborted_clients` | Aborted Clients | NA |  |  |
| `aborted_connects` | Aborted Connects | NA |  |  |
| `bytes_received` | Bytes Received | BYTE |  |  |
| `bytes_sent` | Bytes Sent | BYTE |  |  |
| `connections` | Connections | NA |  |  |
| `locked_connects` | Locked Connects | NA |  |  |
| `max_execution_time_exceeded` | Max Execution Time Exceeded | NA |  |  |
| `max_execution_time_set` | Max Execution Time Set | NA |  |  |
| `max_execution_time_set_failed` | Max Execution Time Set Failed | NA |  |  |
| `max_used_connections` | Max Used Connections (peak) | NA |  |  |
| `ongoing_anonymous_transaction_count` | Ongoing Anonymous Transaction Count (current) | NA |  |  |
| `threads_cached` | Threads Cached (current) | NA |  |  |
| `threads_connected` | Threads Connected (current) | NA |  |  |
| `aborted_connects_delta` | Aborted Connects (per 5-min interval) | NA | > 10 | > 50 |

### Threads Activity (cumulative since server start) (`ThreadsActivity`) — collected every 5 Min

Thread pool activity and configuration — cached, connected, and running thread counts alongside the configured thread-handling mode and connection limit.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `threads_cached` | Threads Cached (current) | NA |  |  |
| `threads_connected` | Threads Connected (current) | NA |  |  |
| `threads_created` | Threads Created | NA |  |  |
| `threads_running` | Threads Running (current) | NA |  |  |
| `slow_launch_threads` | Slow Launch Threads | NA |  |  |
| `uptime` | Uptime | SECOND |  |  |
| `max_connections` | Max Connections (setting) | NA |  |  |
| `thread_handling` | Thread Handling | NA |  |  |
| `connection_saturation_pct` | Connection Saturation (%, current) | PERCENTAGE | > 80 | > 95 |

### Insert Delayed Activity (cumulative since server start) (`InsertDelayedActivity`) — collected every 5 Min

INSERT DELAYED activity counters — errors, active delayed-insert threads, and rows not yet flushed — from the server's status counters.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `delayed_errors` | Delayed Errors | NA |  |  |
| `delayed_insert_threads` | Delayed Insert Threads (current) | NA |  |  |
| `not_flushed_delayed_rows` | Not Flushed Delayed Rows (current) | NA |  |  |
| `delayed_writes` | Delayed Writes | NA |  |  |

### NDB Activity (cumulative since server start) (`NdbActivity`) — collected every 5 Min

NDB Cluster storage engine status counters — conflict function usage and data node counts; empty on servers without the NDB storage engine.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ndb_conflict_fn_max` | Ndb Conflict Fn Max | NA |  |  |
| `ndb_conflict_fn_old` | Ndb Conflict Fn Old | NA |  |  |
| `ndb_number_of_data_nodes` | Ndb Number Of Data Nodes (current) | NA |  |  |
| `ndb_number_of_ready_data_nodes` | Ndb Number Of Ready Data Nodes (current) | NA |  |  |

### Performance Schema Activity (cumulative since server start) (`PerformanceSchemaActivity`) — collected every 5 Min

Performance Schema instrumentation loss counters — how many events, instances, or classes the Performance Schema has had to discard because a configured limit was reached.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `performance_schema_cond_classes_lost` | Performance Schema Cond Classes Lost | NA |  |  |
| `performance_schema_cond_instances_lost` | Performance Schema Cond Instances Lost | NA |  |  |
| `performance_schema_file_classes_lost` | Performance Schema File Classes Lost | NA |  |  |
| `performance_schema_file_handles_lost` | Performance Schema File Handles Lost | NA |  |  |
| `performance_schema_file_instances_lost` | Performance Schema File Instances Lost | NA |  |  |
| `performance_schema_hosts_lost` | Performance Schema Hosts Lost | NA |  |  |
| `performance_schema_index_stat_lost` | Performance Schema Index Stat Lost | NA |  |  |
| `performance_schema_locker_lost` | Performance Schema Locker Lost | NA |  |  |
| `performance_schema_memory_classes_lost` | Performance Schema Memory Classes Lost | NA |  |  |
| `performance_schema_metadata_lock_lost` | Performance Schema Metadata Lock Lost | NA |  |  |
| `performance_schema_mutex_classes_lost` | Performance Schema Mutex Classes Lost | NA |  |  |
| `performance_schema_mutex_instances_lost` | Performance Schema Mutex Instances Lost | NA |  |  |
| `performance_schema_nested_statement_lost` | Performance Schema Nested Statement Lost | NA |  |  |
| `performance_schema_prepared_statements_lost` | Performance Schema Prepared Statements Lost | NA |  |  |
| `performance_schema_program_lost` | Performance Schema Program Lost | NA |  |  |
| `performance_schema_rwlock_classes_lost` | Performance Schema Rwlock Classes Lost | NA |  |  |
| `performance_schema_rwlock_instances_lost` | Performance Schema Rwlock Instances Lost | NA |  |  |
| `performance_schema_session_connect_attrs_longest_seen` | Performance Schema Session Connect Attrs Longest Seen (peak) | BYTE |  |  |
| `performance_schema_table_handles_lost` | Performance Schema Table Handles Lost | NA |  |  |
| `performance_schema_table_instances_lost` | Performance Schema Table Instances Lost | NA |  |  |
| `performance_schema_table_lock_stat_lost` | Performance Schema Table Lock Stat Lost | NA |  |  |
| `performance_schema_thread_classes_lost` | Performance Schema Thread Classes Lost | NA |  |  |
| `performance_schema_thread_instances_lost` | Performance Schema Thread Instances Lost | NA |  |  |

### Table Activity (cumulative since server start) (`TableActivity`) — collected every 5 Min

Table and temporary-table activity — opened tables and definitions, on-disk vs in-memory temporary tables, sorting activity, and table lock waits; created_tmp_tables_delta and created_tmp_disk_tables_delta report those counts as deltas between collections.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `created_tmp_disk_tables` | Created Tmp Disk Tables | NA |  |  |
| `created_tmp_files` | Created Tmp Files | NA |  |  |
| `created_tmp_tables` | Created Tmp Tables | NA |  |  |
| `opened_table_definitions` | Opened Table Definitions | NA |  |  |
| `opened_tables` | Opened Tables | NA |  |  |
| `open_table_definitions` | Open Table Definitions (current) | NA |  |  |
| `open_tables` | Open Tables (current) | NA |  |  |
| `sort_merge_passes` | Sort Merge Passes | NA |  |  |
| `sort_range` | Sort Range | NA |  |  |
| `sort_rows` | Sort Rows | NA |  |  |
| `sort_scan` | Sort Scan | NA |  |  |
| `table_locks_immediate` | Table Locks Immediate | NA |  |  |
| `table_locks_waited` | Table Locks Waited | NA |  |  |
| `uptime` | Uptime | SECOND |  |  |
| `open_files_limit` | Open Files Limit (setting) | NA |  |  |
| `table_open_cache` | Table Open Cache (setting) | NA |  |  |
| `created_tmp_tables_delta` | Created Tmp Tables (per 5-min interval) | NA |  |  |
| `created_tmp_disk_tables_delta` | Created Tmp Disk Tables (per 5-min interval) | NA |  |  |
| `disk_tmp_table_pct` | Disk Tmp Table Ratio (%, per 5-min interval) | PERCENTAGE | > 25 | > 50 |

### Secure Connections Activity (cumulative since server start) (`SecureConnectionsActivity`) — collected every 5 Min

TLS/SSL connection counters and negotiated settings — accepts, renegotiations, session cache activity, cipher, and protocol version.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ssl_accept_renegotiates` | Ssl Accept Renegotiates | NA |  |  |
| `ssl_accepts` | Ssl Accepts | NA |  |  |
| `ssl_callback_cache_hits` | Ssl Callback Cache Hits | NA |  |  |
| `ssl_cipher` | Ssl Cipher (current) | NA |  |  |
| `ssl_cipher_list` | Ssl Cipher List (setting) | NA |  |  |
| `ssl_client_connects` | Ssl Client Connects | NA |  |  |
| `ssl_connect_renegotiates` | Ssl Connect Renegotiates | NA |  |  |
| `ssl_ctx_verify_depth` | Ssl Ctx Verify Depth (setting) | NA |  |  |
| `ssl_ctx_verify_mode` | Ssl Ctx Verify Mode | NA |  |  |
| `ssl_default_timeout` | Ssl Default Timeout (setting) | SECOND |  |  |
| `ssl_finished_accepts` | Ssl Finished Accepts | NA |  |  |
| `ssl_finished_connects` | Ssl Finished Connects | NA |  |  |
| `ssl_server_not_after` | Ssl Server Not After (current) | NA |  |  |
| `ssl_server_not_before` | Ssl Server Not Before (current) | NA |  |  |
| `ssl_session_cache_hits` | Ssl Session Cache Hits | NA |  |  |
| `ssl_session_cache_misses` | Ssl Session Cache Misses | NA |  |  |
| `ssl_session_cache_mode` | Ssl Session Cache Mode (setting) | NA |  |  |
| `ssl_session_cache_overflows` | Ssl Session Cache Overflows | NA |  |  |
| `ssl_session_cache_size` | Ssl Session Cache Size (setting) | NA |  |  |
| `ssl_session_cache_timeout` | Ssl Session Cache Timeout (setting) | SECOND |  |  |
| `ssl_session_cache_timeouts` | Ssl Session Cache Timeouts | NA |  |  |
| `ssl_sessions_reused` | Ssl Sessions Reused | NA |  |  |
| `ssl_used_session_cache_entries` | Ssl Used Session Cache Entries (current) | NA |  |  |
| `ssl_verify_depth` | Ssl Verify Depth (setting) | NA |  |  |
| `ssl_verify_mode` | Ssl Verify Mode | NA |  |  |
| `ssl_version` | Ssl Version (current) | NA |  |  |

### Audit Log Activity (cumulative since server start) (`AuditLogActivity`) — collected every 5 Min

MySQL Enterprise Audit event counters — events written, filtered, and dropped, and audit log size. Requires the Enterprise Audit component; the group collects an empty row when it is not installed.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `audit_log_current_size` | Audit Log Current Size (current) | BYTE |  |  |
| `audit_log_direct_writes` | Audit Log Direct Writes | NA |  |  |
| `audit_log_event_max_drop_size` | Audit Log Event Max Drop Size (peak) | BYTE |  |  |
| `audit_log_events` | Audit Log Events | NA |  |  |
| `audit_log_events_filtered` | Audit Log Events Filtered | NA |  |  |
| `audit_log_events_lost` | Audit Log Events Lost | NA |  |  |
| `audit_log_events_written` | Audit Log Events Written | NA |  |  |
| `audit_log_total_size` | Audit Log Total Size (current) | BYTE |  |  |
| `audit_log_write_waits` | Audit Log Write Waits | NA |  |  |

### Firewall Activity (cumulative since server start) (`FirewallActivity`) — collected every 5 Min

MySQL Enterprise Firewall counters — access granted, denied, and flagged as suspicious, and cached firewall entries. Requires the Enterprise Firewall component; the group collects an empty row when it is not installed.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `firewall_access_denied` | Firewall Access Denied | NA |  |  |
| `firewall_access_granted` | Firewall Access Granted | NA |  |  |
| `firewall_access_suspicious` | Firewall Access Suspicious | NA |  |  |
| `firewall_cached_entries` | Firewall Cached Entries (current) | NA |  |  |

### Sys Schema Status (`SysSchemaStatus`) — collected every 5 Min

Reports whether the MySQL sys schema is present and recent enough for the plug-in's Sys Schema metric groups to collect; the other Sys groups collect empty rows when it is not.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `sys_version` | Sys Version | NA |  |  |
| `sys_supported` | Sys Schema Usable (0/1, 1 = supported) | NA |  | < 1 |
| `status_message` | Sys Status Message | NA |  |  |

### Sys Memory By Event (`SysMemoryByEvent`) — collected every 5 Min

Current and high-water memory allocation per instrumented event, from sys.x$memory_global_by_current_bytes.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `event_name` (key) | Event Name | NA |  |  |
| `current_count` | Current Allocations | NA |  |  |
| `current_alloc` | Current Bytes Allocated | BYTE |  |  |
| `current_avg_alloc` | Current Avg Bytes per Allocation | BYTE |  |  |
| `high_count` | Peak Allocations | NA |  |  |
| `high_alloc` | Peak Bytes Allocated | BYTE |  |  |
| `high_avg_alloc` | Peak Avg Bytes per Allocation | BYTE |  |  |

### Sys IO By Host (`SysIoByHost`) — collected every 5 Min

File I/O count and latency per connecting host, from sys.x$host_summary_by_file_io.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `host` (key) | Host | NA |  |  |
| `ios` | IOs | NA |  |  |
| `io_latency` | IO Latency | MICROSEC |  |  |

### Sys IO By Thread (`SysIoByThread`) — collected every 5 Min

File I/O count and latency per thread, from sys.x$io_by_thread_by_latency.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `thread_id` (key) | Thread Id | NA |  |  |
| `user` | User | NA |  |  |
| `total` | Total | NA |  |  |
| `total_latency` | Total Latency | MICROSEC |  |  |
| `min_latency` | Min Latency | MICROSEC |  |  |
| `avg_latency` | Avg Latency | MICROSEC |  |  |
| `max_latency` | Max Latency | MICROSEC |  |  |
| `processlist_id` | Processlist Id | NA |  |  |

### Sys IO By File (`SysIoByFile`) — collected every 5 Min

File I/O count and latency per file, broken down by read/write/misc activity, from sys.x$io_global_by_file_by_latency.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `file` (key) | File | NA |  |  |
| `total` | Total | NA |  |  |
| `total_latency` | Total Latency | MICROSEC |  |  |
| `count_read` | Count Read | NA |  |  |
| `read_latency` | Read Latency | MICROSEC |  |  |
| `count_write` | Count Write | NA |  |  |
| `write_latency` | Write Latency | MICROSEC |  |  |
| `count_misc` | Count Misc | NA |  |  |
| `misc_latency` | Misc Latency | MICROSEC |  |  |

### Sys IO By Wait (`SysIoByWait`) — collected every 5 Min

File I/O count and latency per wait event, from sys.x$io_global_by_wait_by_latency.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `event_name` (key) | Event Name | NA |  |  |
| `total` | Total | NA |  |  |
| `total_latency` | Total Latency | MICROSEC |  |  |
| `avg_latency` | Avg Latency | MICROSEC |  |  |
| `max_latency` | Max Latency | MICROSEC |  |  |
| `read_latency` | Read Latency | MICROSEC |  |  |
| `write_latency` | Write Latency | MICROSEC |  |  |
| `misc_latency` | Misc Latency | MICROSEC |  |  |
| `count_read` | Count Read | NA |  |  |
| `total_read` | Total Read | BYTE |  |  |
| `avg_read` | Avg Bytes per Read | BYTE |  |  |
| `count_write` | Count Write | NA |  |  |
| `total_written` | Total Written | BYTE |  |  |
| `avg_written` | Avg Bytes per Write | BYTE |  |  |

### Sys Table Statistics (`SysTableStatistics`) — collected every 5 Min

Per-table I/O and DML activity — rows fetched, inserted, updated, and deleted, and I/O bytes/latency — equivalent to sys.x$schema_table_statistics, read directly from performance_schema for compatibility with least-privilege monitoring accounts.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `table_schema` (key) | Table Schema | NA |  |  |
| `table_name` (key) | Table Name | NA |  |  |
| `total` | Total | NA |  |  |
| `total_latency` | Total Latency | MICROSEC |  |  |
| `rows_fetched` | Rows Fetched | NA |  |  |
| `fetch_latency` | Fetch Latency | MICROSEC |  |  |
| `rows_inserted` | Rows Inserted | NA |  |  |
| `insert_latency` | Insert Latency | MICROSEC |  |  |
| `rows_updated` | Rows Updated | NA |  |  |
| `update_latency` | Update Latency | MICROSEC |  |  |
| `rows_deleted` | Rows Deleted | NA |  |  |
| `delete_latency` | Delete Latency | MICROSEC |  |  |
| `io_read_requests` | IO Read Requests | NA |  |  |
| `io_read` | IO Read | BYTE |  |  |
| `io_read_latency` | IO Read Latency | MICROSEC |  |  |
| `io_write_requests` | IO Write Requests | NA |  |  |
| `io_write` | IO Write | BYTE |  |  |
| `io_write_latency` | IO Write Latency | MICROSEC |  |  |
| `io_misc_requests` | IO Misc Requests | NA |  |  |
| `io_misc_latency` | IO Misc Latency | MICROSEC |  |  |

### Sys User Summary (`SysUserSummary`) — collected every 5 Min

Per-user activity summary — statements, table scans, file I/O, connections, and memory — from sys.x$user_summary.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `user` (key) | User | NA |  |  |
| `statements` | Statements | NA |  |  |
| `statement_latency` | Statement Latency | MICROSEC |  |  |
| `statement_avg_latency` | Statement Avg Latency | MICROSEC |  |  |
| `table_scans` | Full Table Scans | NA |  |  |
| `file_ios` | File IOs | NA |  |  |
| `file_io_latency` | File IO Latency | MICROSEC |  |  |
| `current_connections` | Current Connections | NA |  |  |
| `total_connections` | Total Connections | NA |  |  |
| `unique_hosts` | Unique Hosts | NA |  |  |
| `current_memory` | Current Memory | BYTE |  |  |
| `total_memory_allocated` | Total Memory Allocated | BYTE |  |  |

### Sys Host Summary (`SysHostSummary`) — collected every 5 Min

Per-host activity summary — statements, table scans, file I/O, connections, and memory — from sys.x$host_summary.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `host` (key) | Host | NA |  |  |
| `statements` | Statements | NA |  |  |
| `statement_latency` | Statement Latency | MICROSEC |  |  |
| `statement_avg_latency` | Statement Avg Latency | MICROSEC |  |  |
| `table_scans` | Full Table Scans | NA |  |  |
| `file_ios` | File IOs | NA |  |  |
| `file_io_latency` | File IO Latency | MICROSEC |  |  |
| `current_connections` | Current Connections | NA |  |  |
| `total_connections` | Total Connections | NA |  |  |
| `unique_users` | Unique Users | NA |  |  |
| `current_memory` | Current Memory | BYTE |  |  |
| `total_memory_allocated` | Total Memory Allocated | BYTE |  |  |

### Sys Statement By Latency (`SysStatementByLatency`) — collected every 5 Min

Top 25 statement digests by total execution latency, from sys.x$statement_analysis.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `digest` (key) | Digest | NA |  |  |
| `query` | Query | NA |  |  |
| `db` (key) | Db | NA |  |  |
| `full_scan` | Full Scan ("*" = full scan) | NA |  |  |
| `exec_count` | Executions (cumulative) | NA |  |  |
| `err_count` | Errors (cumulative) | NA |  |  |
| `warn_count` | Warnings (cumulative) | NA |  |  |
| `total_latency` | Total Latency (us, cumulative) | MICROSEC |  |  |
| `max_latency` | Max Latency (us, slowest execution) | MICROSEC |  |  |
| `avg_latency` | Avg Latency (us per execution) | MICROSEC |  |  |
| `lock_latency` | Lock Wait Time (us, cumulative) | MICROSEC |  |  |
| `rows_sent` | Rows Sent to Client (cumulative) | NA |  |  |
| `rows_examined` | Rows Examined (cumulative) | NA |  |  |
| `rows_affected` | Rows Affected (cumulative) | NA |  |  |
| `tmp_tables` | Temp Tables Created (cumulative) | NA |  |  |
| `tmp_disk_tables` | Temp Tables On Disk (cumulative) | NA |  |  |
| `first_seen` | First Seen | NA |  |  |

### Sys Statement By Exec Count (`SysStatementByExecCount`) — collected every 5 Min

Top 25 statement digests by execution count, from sys.x$statement_analysis.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `digest` (key) | Digest | NA |  |  |
| `query` | Query | NA |  |  |
| `db` (key) | Db | NA |  |  |
| `full_scan` | Full Scan ("*" = full scan) | NA |  |  |
| `exec_count` | Executions (cumulative) | NA |  |  |
| `err_count` | Errors (cumulative) | NA |  |  |
| `warn_count` | Warnings (cumulative) | NA |  |  |
| `total_latency` | Total Latency (us, cumulative) | MICROSEC |  |  |
| `max_latency` | Max Latency (us, slowest execution) | MICROSEC |  |  |
| `avg_latency` | Avg Latency (us per execution) | MICROSEC |  |  |
| `lock_latency` | Lock Wait Time (us, cumulative) | MICROSEC |  |  |
| `rows_sent` | Rows Sent to Client (cumulative) | NA |  |  |
| `rows_examined` | Rows Examined (cumulative) | NA |  |  |
| `rows_affected` | Rows Affected (cumulative) | NA |  |  |
| `tmp_tables` | Temp Tables Created (cumulative) | NA |  |  |
| `tmp_disk_tables` | Temp Tables On Disk (cumulative) | NA |  |  |
| `first_seen` | First Seen | NA |  |  |

### Sys Statement By First Seen (`SysStatementByFirstSeen`) — collected every 5 Min

Top 25 statement digests by most recent first-seen time, from sys.x$statement_analysis.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `digest` (key) | Digest | NA |  |  |
| `query` | Query | NA |  |  |
| `db` (key) | Db | NA |  |  |
| `full_scan` | Full Scan ("*" = full scan) | NA |  |  |
| `exec_count` | Executions (cumulative) | NA |  |  |
| `err_count` | Errors (cumulative) | NA |  |  |
| `warn_count` | Warnings (cumulative) | NA |  |  |
| `total_latency` | Total Latency (us, cumulative) | MICROSEC |  |  |
| `max_latency` | Max Latency (us, slowest execution) | MICROSEC |  |  |
| `avg_latency` | Avg Latency (us per execution) | MICROSEC |  |  |
| `lock_latency` | Lock Wait Time (us, cumulative) | MICROSEC |  |  |
| `rows_sent` | Rows Sent to Client (cumulative) | NA |  |  |
| `rows_examined` | Rows Examined (cumulative) | NA |  |  |
| `rows_affected` | Rows Affected (cumulative) | NA |  |  |
| `tmp_tables` | Temp Tables Created (cumulative) | NA |  |  |
| `tmp_disk_tables` | Temp Tables On Disk (cumulative) | NA |  |  |
| `first_seen` | First Seen | NA |  |  |

### Sys InnoDB Lock Waits (`SysInnodbLockWaits`) — collected every 5 Min

Current InnoDB row-lock waits — the waiting and blocking lock, transaction, and session for each — equivalent to sys.x$innodb_lock_waits, read directly from performance_schema for compatibility with least-privilege monitoring accounts.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `waiting_lock_id` (key) | Waiting Lock Id | NA |  |  |
| `blocking_lock_id` (key) | Blocking Lock Id | NA |  |  |
| `locked_schema` | Locked Schema | NA |  |  |
| `locked_table` | Locked Table | NA |  |  |
| `locked_index` | Locked Index | NA |  |  |
| `locked_type` | Locked Type (RECORD \| TABLE) | NA |  |  |
| `waiting_lock_mode` | Waiting Lock Mode | NA |  |  |
| `blocking_lock_mode` | Blocking Lock Mode | NA |  |  |
| `waiting_pid` | Waiting Pid | NA |  |  |
| `blocking_pid` | Blocking Pid | NA |  |  |
| `waiting_trx_id` | Waiting Trx Id | NA |  |  |
| `blocking_trx_id` | Blocking Trx Id | NA |  |  |
| `waiting_seconds` | Lock Wait Age (seconds; -1 = unknown) | SECOND |  |  |

### Sys Table Lock Waits (`SysTableLockWaits`) — collected every 5 Min

Current metadata (table) lock waits — pending vs. granted locks and the sessions holding them — equivalent to sys.x$schema_table_lock_waits, read directly from performance_schema for compatibility with least-privilege monitoring accounts.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `object_schema` (key) | Object Schema | NA |  |  |
| `object_name` (key) | Object Name | NA |  |  |
| `waiting_thread_id` (key) | Waiting Thread Id | NA |  |  |
| `waiting_pid` | Waiting Pid | NA |  |  |
| `waiting_lock_type` | Waiting Lock Type (SHARED_READ \| EXCLUSIVE \| ...) | NA |  |  |
| `waiting_lock_duration` | Waiting Lock Duration | NA |  |  |
| `blocking_thread_id` | Blocking Thread Id | NA |  |  |
| `blocking_pid` | Blocking Pid | NA |  |  |
| `blocking_lock_type` | Blocking Lock Type (SHARED_READ \| EXCLUSIVE \| ...) | NA |  |  |
| `blocking_lock_duration` | Blocking Lock Duration | NA |  |  |
| `waiting_seconds` | Wait Time (seconds in MDL wait state; -1 = unknown) | SECOND |  |  |

### Sys Processlist (`SysProcesslist`) — collected every 5 Min

Active, non-idle sessions and their current statement, from sys.x$processlist.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `thd_id` (key) | Thd Id | NA |  |  |
| `conn_id` | Conn Id | NA |  |  |
| `user` | User | NA |  |  |
| `db` | Db | NA |  |  |
| `command` | Command | NA |  |  |
| `state` | State | NA |  |  |
| `time` | Time in Current State | SECOND |  |  |
| `current_statement` | Current Statement | NA |  |  |
| `statement_latency` | Statement Running Time | MICROSEC |  |  |
| `lock_latency` | Lock Wait Time | MICROSEC |  |  |
| `rows_examined` | Rows Examined by Statement | NA |  |  |
| `rows_sent` | Rows Sent by Statement | NA |  |  |
| `rows_affected` | Rows Affected by Statement | NA |  |  |
| `tmp_tables` | Temp Tables Created by Statement | NA |  |  |
| `tmp_disk_tables` | Temp Tables on Disk by Statement | NA |  |  |
| `trx_state` | Transaction State (ACTIVE \| COMMITTED \| ROLLED BACK) | NA |  |  |

### Backup History (`BackupHistory`) — collected every 1 Hr

Recent backup runs across supported backup tools. Reads MySQL Enterprise Backup's mysql.backup_history and Percona XtraBackup's PERCONA_SCHEMA.xtrabackup_history when present; an absent tool is reported as not detected and raises no alert.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `source` (key) | Source | NA |  |  |
| `backup_id` (key) | Backup ID | NA |  |  |
| `backup_type` | Backup Type (full \| incremental \| partial) | NA |  |  |
| `start_time` | Start Time | NA |  |  |
| `end_time` | End Time | NA |  |  |
| `run_seconds` | Run Time (sec) | SECOND |  |  |
| `lock_seconds` | Lock Time (sec) | SECOND |  |  |
| `end_lsn` | End LSN | NA |  |  |
| `binlog_position` | Binlog Position (PITR) | NA |  |  |
| `exit_state` | Exit State (SUCCESS \| COMPLETED \| INCOMPLETE \| ...) | NA |  |  |
| `success` | Success (0/1: 1 = backup completed OK) | NA |  |  |

### Backup Status (`BackupStatus`) — collected every 1 Hr

Single-row backup health summary — presence of each backup tool, the most recent backup attempt, and hours since the last success. Reads MySQL Enterprise Backup's mysql.backup_history and Percona XtraBackup's PERCONA_SCHEMA.xtrabackup_history when present; an absent tool is reported as not detected and raises no alert.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `meb_present` | MEB Detected (0/1: 1 = mysql.backup_history exists) | NA |  |  |
| `pxb_present` | XtraBackup Detected (0/1: 1 = PERCONA_SCHEMA exists) | NA |  |  |
| `pxb_history_enabled` | XtraBackup History Enabled (0/1: 1 = history table exists) | NA |  |  |
| `last_source` | Last Backup Source | NA |  |  |
| `last_exit_state` | Last Exit State (SUCCESS \| COMPLETED \| INCOMPLETE \| ...) | NA |  |  |
| `last_successful_end_time` | Last Successful Backup | NA |  |  |
| `hours_since_last_success` | Hours Since Last Successful Backup (empty = none/unknown) | HOURS | > 26 | > 50 |
| `last_backup_failed` | Last Backup Failed (0/1: 1 = failed) | NA |  | > 0 |
| `never_succeeded` | Never Succeeded (0/1: 1 = no success on record) | NA |  | > 0 |
| `backup_history_visible` | Backup History Visible (0/1: 1 = backup history table present) | NA |  |  |

### Character Set (`CharacterSet`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Character Set settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `CLIENT` | Client | NA |  |  |
| `CONNECTION` | Connection | NA |  |  |
| `DATABASE` | Database | NA |  |  |
| `DIRECTORY` | Directory | NA |  |  |
| `FILESYSTEM` | Filesystem | NA |  |  |
| `RESULTS` | Results | NA |  |  |
| `SERVER` | Server | NA |  |  |
| `SYSTEM` | System | NA |  |  |

### Connection Buffers (`ConnectionBuffers`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Connection Buffers settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BULK_INSERT_BUFFER_SIZE` | Bulk Insert Buffer Size (bytes) | BYTE |  |  |
| `JOIN_BUFFER_SIZE` | Join Buffer Size (bytes) | BYTE |  |  |
| `MAX_ALLOWED_PACKET` | Max Allowed Packet (bytes) | BYTE |  |  |
| `NET_BUFFER_LENGTH` | Net Buffer Length (bytes) | BYTE |  |  |
| `PRELOAD_BUFFER_SIZE` | Preload Buffer Size (bytes) | BYTE |  |  |
| `QUERY_ALLOC_BLOCK_SIZE` | Query Alloc Block Size (bytes) | BYTE |  |  |
| `QUERY_PREALLOC_SIZE` | Query Prealloc Size (bytes) | BYTE |  |  |
| `READ_BUFFER_SIZE` | Read Buffer Size (bytes) | BYTE |  |  |
| `READ_RND_BUFFER_SIZE` | Read Rnd Buffer Size (bytes) | BYTE |  |  |
| `SORT_BUFFER_SIZE` | Sort Buffer Size (bytes) | BYTE |  |  |
| `STORED_PROGRAM_CACHE` | Stored Program Cache (routines per session) | NA |  |  |
| `THREAD_STACK` | Thread Stack (bytes) | BYTE |  |  |
| `TRANSACTION_ALLOC_BLOCK_SIZE` | Transaction Alloc Block Size (bytes) | BYTE |  |  |
| `TRANSACTION_PREALLOC_SIZE` | Transaction Prealloc Size (bytes) | BYTE |  |  |

### Metadata (`Metadata`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Metadata settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `LICENSE` | License | NA |  |  |
| `PROTOCOL_VERSION` | Protocol Version (number) | NA |  |  |
| `VERSION` | Version | NA |  |  |
| `VERSION_COMMENT` | Version Comment | NA |  |  |
| `VERSION_COMPILE_MACHINE` | Version Compile Machine | NA |  |  |
| `VERSION_COMPILE_OS` | Version Compile OS | NA |  |  |

### Replication Source Configuration (`ReplicationSourceConfig`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Replication Source Configuration settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `AUTO_INCREMENT_INCREMENT` | Auto-Increment Step | NA |  |  |
| `AUTO_INCREMENT_OFFSET` | Auto-Increment Start Offset | NA |  |  |
| `ENFORCE_GTID_CONSISTENCY` | Enforce Gtid Consistency | NA |  |  |
| `GTID_EXECUTED` | Gtid Executed | NA |  |  |
| `GTID_EXECUTED_COMPRESS_PERIOD` | GTID Compression Period (transactions) | NA |  |  |
| `GTID_MODE` | Gtid Mode | NA |  |  |
| `GTID_OWNED` | Gtid Owned | NA |  |  |
| `GTID_PURGED` | Gtid Purged | NA |  |  |
| `SEMI_SYNC_SOURCE_ENABLED` | Semi Sync Source Enabled | NA |  |  |
| `SEMI_SYNC_SOURCE_TIMEOUT` | Semi-Sync Source Timeout (ms) | MILLISECONDS |  |  |
| `SEMI_SYNC_SOURCE_TRACE_LEVEL` | Semi-Sync Source Trace Level (bit mask) | NA |  |  |
| `SEMI_SYNC_SRC_WAIT_NO_REPLICA` | Semi Sync Source Wait No Replica | NA |  |  |
| `SERVER_ID` | Server ID (this server) | NA |  |  |
| `SOURCE_VERIFY_CHECKSUM` | Source Verify Checksum | NA |  |  |

### Replication Replica Configuration (`ReplicationReplicaConfig`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Replication Replica Configuration settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ALLOW_BATCHING` | Allow Batching | NA |  |  |
| `CHECKPOINT_GROUP` | Checkpoint Group (transactions) | NA |  |  |
| `CHECKPOINT_PERIOD` | Checkpoint Period (ms) | MILLISECONDS |  |  |
| `COMPRESSED_PROTOCOL` | Compressed Protocol | NA |  |  |
| `EXEC_MODE` | Exec Mode | NA |  |  |
| `GTID_MODE` | Gtid Mode | NA |  |  |
| `INIT_REPLICA` | Init Replica | NA |  |  |
| `LOAD_TMPDIR` | Load Tmpdir | NA |  |  |
| `LOG_REPLICA_UPDATES` | Log Replica Updates | NA |  |  |
| `MAX_ALLOWED_PACKET` | Max Allowed Packet (bytes) | BYTE |  |  |
| `MAX_RELAY_LOG_SIZE` | Max Relay Log Size (bytes; 0 = max_binlog_size) | BYTE |  |  |
| `NET_TIMEOUT` | Net Timeout (s) | SECOND |  |  |
| `PARALLEL_TYPE` | Parallel Type (DATABASE \| LOGICAL_CLOCK) | NA |  |  |
| `PARALLEL_WORKERS` | Parallel Workers (threads) | NA |  |  |
| `PENDING_JOBS_SIZE_MAX` | Pending Jobs Size Max (bytes) | BYTE |  |  |
| `PRESERVE_COMMIT_ORDER` | Preserve Commit Order | NA |  |  |
| `READ_ONLY` | Read Only | NA |  |  |
| `RELAY_LOG` | Relay Log | NA |  |  |
| `RELAY_LOG_BASENAME` | Relay Log Basename | NA |  |  |
| `RELAY_LOG_INDEX` | Relay Log Index | NA |  |  |
| `RELAY_LOG_PURGE` | Relay Log Purge | NA |  |  |
| `RELAY_LOG_RECOVERY` | Relay Log Recovery | NA |  |  |
| `RELAY_LOG_SPACE_LIMIT` | Relay Log Space Limit (bytes; 0 = unlimited) | BYTE |  |  |
| `REPORT_HOST` | Report Host | NA |  |  |
| `REPORT_PORT` | Report Port (TCP) | NA |  |  |
| `REPORT_USER` | Report User | NA |  |  |
| `SEMI_SYNC_REPLICA_ENABLED` | Semi Sync Replica Enabled | NA |  |  |
| `SEMI_SYNC_REPLICA_TRACE_LEVEL` | Semi-Sync Replica Trace Level (bit mask) | NA |  |  |
| `SERVER_ID` | Server ID (this server) | NA |  |  |
| `SKIP_ERRORS` | Skip Errors | NA |  |  |
| `SQL_VERIFY_CHECKSUM` | Sql Verify Checksum | NA |  |  |
| `SYNC_SOURCE_INFO` | Sync Source Info (events) | NA |  |  |
| `SYNC_RELAY_LOG` | Sync Relay Log (events) | NA |  |  |
| `SYNC_RELAY_LOG_INFO` | Sync Relay Log Info (transactions) | NA |  |  |
| `TRANSACTION_RETRIES` | Transaction Retries (limit) | NA |  |  |
| `TYPE_CONVERSIONS` | Type Conversions | NA |  |  |

### Information Schema Configuration (`InformationSchema`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Information Schema Configuration settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `STATS_EXPIRY` | Stats Expiry (s) | SECOND |  |  |

### Data Dictionary Configuration (`DataDictionary`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Data Dictionary Configuration settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `SCHEMA_DEFINITION_CACHE` | Schema Definition Cache (objects) | NA |  |  |
| `TABLE_DEFINITION_CACHE` | Table Definition Cache (objects) | NA |  |  |
| `TABLESPACE_DEFINITION_CACHE` | Tablespace Definition Cache (objects) | NA |  |  |
| `STORED_PROGRAM_DEF_CACHE` | Stored Program Definition Cache (objects) | NA |  |  |

### Binary Logs (`BinaryLogs`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Binary Logs settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BINLOG_CACHE_SIZE` | Binlog Cache Size (bytes) | BYTE |  |  |
| `BINLOG_CHECKSUM` | Binlog Checksum | NA |  |  |
| `BINLOG_DIRECT_NON_TRX_UPDATES` | Binlog Direct Non Trx Updates | NA |  |  |
| `BINLOG_ERROR_ACTION` | Binlog Error Action | NA |  |  |
| `BINLOG_EXPIRE_LOGS_SECONDS` | Binlog Expire Logs (s) | SECOND |  |  |
| `BINLOG_FORMAT` | Binlog Format | NA |  |  |
| `BINLOG_GROUP_COMMIT_SYNC_DELAY` | Group Commit Sync Delay (us) | MICROSEC |  |  |
| `BINLOG_GROUP_COMMIT_SYNC_NDC` | Group Commit No-Delay Count (transactions) | NA |  |  |
| `BINLOG_GTID_SIMPLE_RECOVERY` | Binlog Gtid Simple Recovery | NA |  |  |
| `BINLOG_MAX_FLUSH_QUEUE_TIME` | Max Flush Queue Time (us) | MICROSEC |  |  |
| `BINLOG_ORDER_COMMITS` | Binlog Order Commits | NA |  |  |
| `BINLOG_ROW_IMAGE` | Binlog Row Image | NA |  |  |
| `BINLOG_ROW_METADATA` | Binlog Row Metadata | NA |  |  |
| `BINLOG_ROWS_QUERY_LOG_EVENT` | Binlog Rows Query Log Event | NA |  |  |
| `BINLOG_ROW_VALUE_OPTIONS` | Binlog Row Value Options | NA |  |  |
| `BINLOG_STMT_CACHE_SIZE` | Binlog Stmt Cache Size (bytes) | BYTE |  |  |
| `BINLOG_TRX_DEP_HISTORY_SIZE` | Trx Dependency History Size (row hashes) | NA |  |  |
| `BINLOG_TRUST_FUNC_CREATORS` | Binlog Trust Func Creators | NA |  |  |
| `LOG_BIN_BASENAME` | Log Bin Basename | NA |  |  |
| `LOG_BIN` | Log Bin | NA |  |  |
| `LOG_BIN_INDEX` | Log Bin Index | NA |  |  |
| `MAX_BINLOG_CACHE_SIZE` | Max Binlog Cache Size (bytes) | BYTE |  |  |
| `MAX_BINLOG_SIZE` | Max Binlog Size (bytes) | BYTE |  |  |
| `MAX_BINLOG_STMT_CACHE_SIZE` | Max Binlog Stmt Cache Size (bytes) | BYTE |  |  |
| `SYNC_BINLOG` | Sync Binlog (0 = OS flush \| N = fsync every N commit groups) | NA |  |  |

### Secure Connections (`SecureConnections`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Secure Connections settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `CA` | Ca | NA |  |  |
| `CA_PATH` | Ca Path | NA |  |  |
| `CERT` | Cert | NA |  |  |
| `CIPHER` | Cipher | NA |  |  |
| `CRL` | Crl | NA |  |  |
| `CRL_PATH` | Crl Path | NA |  |  |
| `KEY` | Key | NA |  |  |
| `TLS_VERSION` | Tls Version | NA |  |  |
| `REQUIRE_SECURE_TRANSPORT` | Require Secure Transport | NA |  |  |

### Audit Log (`AuditLog`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Audit Log settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BUFFER_SIZE` | Buffer Size | NA |  |  |
| `CONN_POLICY` | Conn Policy | NA |  |  |
| `ENABLED_STATE` | Audit Log Disable Switch (ON = logging off \| OFF = logging on) | NA |  |  |
| `EXCLUDE_ACCOUNTS` | Exclude Accounts | NA |  |  |
| `AUDIT_LOG_FILE` | Audit Log File | NA |  |  |
| `FLUSH` | Flush | NA |  |  |
| `FORMAT` | Format | NA |  |  |
| `INCLUDE_ACCOUNTS` | Include Accounts | NA |  |  |
| `POLICY` | Policy | NA |  |  |
| `ROTATE_ON_SIZE` | Rotate On Size | NA |  |  |
| `STMT_POLICY` | Stmt Policy | NA |  |  |
| `STRATEGY` | Strategy | NA |  |  |

### Firewall (`Firewall`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Firewall settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `MAX_QUERY_SIZE` | Max Query Size | NA |  |  |
| `FIREWALL_MODE` | Firewall Mode | NA |  |  |
| `TRACE` | Trace | NA |  |  |

### Connection (`Connection`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Connection settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BACK_LOG` | Back Log (pending connections) | NA |  |  |
| `CONNECT_TIMEOUT` | Connect Timeout (s) | SECOND |  |  |
| `INIT_CONNECT` | Init Connect | NA |  |  |
| `INTERACTIVE_TIMEOUT` | Interactive Timeout (s) | SECOND |  |  |
| `MAX_CONNECT_ERRORS` | Max Connect Errors (limit) | NA |  |  |
| `MAX_CONNECTIONS` | Max Connections (limit) | NA |  |  |
| `MAX_USER_CONNECTIONS` | Max User Connections (0 = no limit) | NA |  |  |
| `NET_BUFFER_LENGTH` | Net Buffer Length (bytes) | BYTE |  |  |
| `NET_READ_TIMEOUT` | Net Read Timeout (s) | SECOND |  |  |
| `NET_RETRY_COUNT` | Net Retry Count (retries) | NA |  |  |
| `NET_WRITE_TIMEOUT` | Net Write Timeout (s) | SECOND |  |  |
| `OFFLINE_MODE` | Offline Mode | NA |  |  |
| `SESSION_TRACK_GTIDS` | Session Track Gtids | NA |  |  |
| `SESSION_TRACK_SCHEMA` | Session Track Schema | NA |  |  |
| `SESSION_TRACK_STATE_CHANGE` | Session Track State Change | NA |  |  |
| `SESSION_TRACK_SYSTEM_VARIABLES` | Session Track System Variables | NA |  |  |
| `SKIP_NAME_RESOLVE` | Skip Name Resolve | NA |  |  |
| `WAIT_TIMEOUT` | Wait Timeout (s) | SECOND |  |  |

### Connection (`ConnectionLive`) — collected on demand

Real-time mirror of the Connection configuration snapshot — the same connection-related server variables, refreshed on demand instead of on the configuration schedule.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BACK_LOG` | Back Log (pending connections) | NA |  |  |
| `CONNECT_TIMEOUT` | Connect Timeout (s) | SECOND |  |  |
| `INIT_CONNECT` | Init Connect | NA |  |  |
| `INTERACTIVE_TIMEOUT` | Interactive Timeout (s) | SECOND |  |  |
| `MAX_CONNECT_ERRORS` | Max Connect Errors (limit) | NA |  |  |
| `MAX_CONNECTIONS` | Max Connections (limit) | NA |  |  |
| `MAX_USER_CONNECTIONS` | Max User Connections (0 = no limit) | NA |  |  |
| `NET_BUFFER_LENGTH` | Net Buffer Length (bytes) | BYTE |  |  |
| `NET_READ_TIMEOUT` | Net Read Timeout (s) | SECOND |  |  |
| `NET_RETRY_COUNT` | Net Retry Count (retries) | NA |  |  |
| `NET_WRITE_TIMEOUT` | Net Write Timeout (s) | SECOND |  |  |
| `OFFLINE_MODE` | Offline Mode | NA |  |  |
| `SESSION_TRACK_GTIDS` | Session Track Gtids | NA |  |  |
| `SESSION_TRACK_SCHEMA` | Session Track Schema | NA |  |  |
| `SESSION_TRACK_STATE_CHANGE` | Session Track State Change | NA |  |  |
| `SESSION_TRACK_SYSTEM_VARIABLES` | Session Track System Variables | NA |  |  |
| `SKIP_NAME_RESOLVE` | Skip Name Resolve | NA |  |  |
| `WAIT_TIMEOUT` | Wait Timeout (s) | SECOND |  |  |

### Environment (`Environment`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Environment settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BASEDIR` | Basedir | NA |  |  |
| `CORE_FILE` | Core File | NA |  |  |
| `DATADIR` | Datadir | NA |  |  |
| `HOSTNAME` | Hostname | NA |  |  |
| `INIT_FILE` | Init File | NA |  |  |
| `KEEP_FILES_ON_CREATE` | Keep Files On Create | NA |  |  |
| `LARGE_FILES_SUPPORT` | Large Files Support | NA |  |  |
| `LARGE_PAGES` | Large Pages | NA |  |  |
| `LARGE_PAGE_SIZE` | Large Page Size (bytes) | BYTE |  |  |
| `LOCKED_IN_MEMORY` | Locked In Memory | NA |  |  |
| `LOWER_CASE_FILE_SYSTEM` | Lower Case File System | NA |  |  |
| `OPEN_FILES_LIMIT` | Open Files Limit (files) | NA |  |  |
| `PERSISTED_GLOBALS_LOAD` | Persisted Globals Load | NA |  |  |
| `PID_FILE` | Pid File | NA |  |  |
| `PLUGIN_DIR` | Plugin Dir | NA |  |  |
| `SKIP_EXTERNAL_LOCKING` | Skip External Locking | NA |  |  |
| `SQL_MODE` | Sql Mode | NA |  |  |
| `TMPDIR` | Tmpdir | NA |  |  |

### HostCache (`HostCache`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's HostCache settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `HOST_CACHE_SIZE` | Host Cache Size (entries) | NA |  |  |

### Threads (`Threads`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Threads settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `THREAD_CACHE_SIZE` | Thread Cache Size (threads) | NA |  |  |
| `THREAD_HANDLING` | Thread Handling | NA |  |  |
| `SLOW_LAUNCH_TIME` | Slow Launch Time (s) | SECOND |  |  |
| `THREAD_STACK` | Thread Stack (bytes) | BYTE |  |  |

### Threads (`ThreadsLive`) — collected on demand

Real-time mirror of the Threads configuration snapshot — the same thread-handling server variables, refreshed on demand instead of on the configuration schedule.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `THREAD_CACHE_SIZE` | Thread Cache Size (threads) | NA |  |  |
| `THREAD_HANDLING` | Thread Handling | NA |  |  |
| `SLOW_LAUNCH_TIME` | Slow Launch Time (s) | SECOND |  |  |
| `THREAD_STACK` | Thread Stack (bytes) | BYTE |  |  |

### Transactions (`Transactions`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Transactions settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `AUTOCOMMIT` | Autocommit | NA |  |  |
| `COMPLETION_TYPE` | Completion Type (NO_CHAIN \| CHAIN \| RELEASE) | NA |  |  |
| `TRANSACTION_ISOLATION` | Transaction Isolation | NA |  |  |
| `TRANSACTION_READ_ONLY` | Transaction Read Only | NA |  |  |

### Networking (`Networking`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Networking settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BIND_ADDRESS` | Bind Address | NA |  |  |
| `PORT` | Port (TCP listen) | NA |  |  |
| `SKIP_NAME_RESOLVE` | Skip Name Resolve | NA |  |  |
| `SKIP_NETWORKING` | Skip Networking | NA |  |  |
| `SOCKET` | Socket | NA |  |  |

### Optimizer (`Optimizer`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Optimizer settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `END_MARKERS_IN_JSON` | End Markers In Json | NA |  |  |
| `EQ_RANGE_INDEX_DIVE_LIMIT` | Eq Range Index Dive Limit (ranges) | NA |  |  |
| `HISTOGRAM_GEN_MAX_MEM_SIZE` | Histogram Gen Max Memory (bytes) | BYTE |  |  |
| `MAX_LENGTH_FOR_SORT_DATA` | Max Length For Sort Data (bytes) | BYTE |  |  |
| `MAX_SEEKS_FOR_KEY` | Max Seeks For Key (seeks) | NA |  |  |
| `MAX_SORT_LENGTH` | Max Sort Length (bytes) | BYTE |  |  |
| `PRUNE_LEVEL` | Prune Level (0 = exhaustive \| 1 = heuristic) | NA |  |  |
| `RANGE_ALLOC_BLOCK_SIZE` | Range Alloc Block Size (bytes) | BYTE |  |  |
| `SEARCH_DEPTH` | Search Depth (tables) | NA |  |  |
| `SWITCH_VALUE` | Switch Value | NA |  |  |
| `TRACE` | Trace | NA |  |  |
| `TRACE_FEATURES` | Trace Features | NA |  |  |
| `TRACE_LIMIT` | Trace Limit (traces) | NA |  |  |
| `TRACE_MAX_MEM_SIZE` | Trace Max Memory (bytes) | BYTE |  |  |
| `TRACE_OFFSET` | Trace Offset (traces) | NA |  |  |
| `WINDOWING_USE_HIGH_PRECISION` | Windowing Use High Precision | NA |  |  |

### Optimizer (`OptimizerLive`) — collected on demand

Real-time mirror of the Optimizer configuration snapshot — the same query optimizer server variables, refreshed on demand instead of on the configuration schedule.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `END_MARKERS_IN_JSON` | End Markers In Json | NA |  |  |
| `EQ_RANGE_INDEX_DIVE_LIMIT` | Eq Range Index Dive Limit (ranges) | NA |  |  |
| `HISTOGRAM_GEN_MAX_MEM_SIZE` | Histogram Gen Max Memory (bytes) | BYTE |  |  |
| `MAX_LENGTH_FOR_SORT_DATA` | Max Length For Sort Data (bytes) | BYTE |  |  |
| `MAX_SEEKS_FOR_KEY` | Max Seeks For Key (seeks) | NA |  |  |
| `MAX_SORT_LENGTH` | Max Sort Length (bytes) | BYTE |  |  |
| `PRUNE_LEVEL` | Prune Level (0 = exhaustive \| 1 = heuristic) | NA |  |  |
| `RANGE_ALLOC_BLOCK_SIZE` | Range Alloc Block Size (bytes) | BYTE |  |  |
| `SEARCH_DEPTH` | Search Depth (tables) | NA |  |  |
| `SWITCH_VALUE` | Switch Value | NA |  |  |
| `TRACE` | Trace | NA |  |  |
| `TRACE_FEATURES` | Trace Features | NA |  |  |
| `TRACE_LIMIT` | Trace Limit (traces) | NA |  |  |
| `TRACE_MAX_MEM_SIZE` | Trace Max Memory (bytes) | BYTE |  |  |
| `TRACE_OFFSET` | Trace Offset (traces) | NA |  |  |
| `WINDOWING_USE_HIGH_PRECISION` | Windowing Use High Precision | NA |  |  |

### Logging (`Logging`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Logging settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `GENERAL_LOG` | General Log | NA |  |  |
| `GENERAL_LOG_FILE` | General Log File | NA |  |  |
| `LOG_ERROR` | Log Error | NA |  |  |
| `LOG_ERROR_SERVICES` | Log Error Services | NA |  |  |
| `LOG_ERROR_VERBOSITY` | Log Error Verbosity (1 = errors \| 2 = +warnings \| 3 = +notes) | NA |  |  |
| `LOG_OUTPUT` | Log Output | NA |  |  |
| `LOG_TIMESTAMPS` | Log Timestamps | NA |  |  |
| `SQL_LOG_DISABLED` | Sql Log Disabled | NA |  |  |

### Slow Query Logging (`SlowQueryLogging`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Slow Query Logging settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `LOG_QUERIES_NOT_USING_INDEXES` | Log Queries Not Using Indexes | NA |  |  |
| `LOG_SLOW_ADMIN_STMTS` | Log Slow Admin Stmts | NA |  |  |
| `LOG_SLOW_QUERIES` | Log Slow Queries | NA |  |  |
| `LOG_SLOW_SLAVE_STMTS` | Log Slow Slave Stmts | NA |  |  |
| `THROTTLE_STMTS_NOT_INDX` | Throttle Non-Indexed Queries (per minute) | NA |  |  |
| `LONG_QUERY_TIME` | Long Query Time (s) | SECOND |  |  |
| `MIN_EXAMINED_ROW_LIMIT` | Min Examined Row Limit (rows) | NA |  |  |
| `SLOW_QUERY_LOG_FILE` | Slow Query Log File | NA |  |  |

### Statement Processing (`StatementProcessing`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Statement Processing settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `AUTO_IS_NULL` | Auto Is Null | NA |  |  |
| `BIG_SELECTS` | Big Selects | NA |  |  |
| `BUFFER_RESULT` | Buffer Result | NA |  |  |
| `CTE_MAX_RECURSION_DEPTH` | CTE Max Recursion Depth (levels) | NA |  |  |
| `DIV_PRECISION_INCREMENT` | Division Precision Increment (digits) | NA |  |  |
| `GROUP_CONCAT_MAX_LEN` | Group Concat Max Length (bytes) | BYTE |  |  |
| `INTERNAL_TMP_MEM_STORAGE_ENG` | Internal Tmp Mem Storage Eng | NA |  |  |
| `MAX_DIGEST_LENGTH` | Max Digest Length (bytes) | BYTE |  |  |
| `MAX_ERROR_COUNT` | Max Error Count (messages) | NA |  |  |
| `MAX_EXECUTION_TIME` | Max Execution Time (ms; 0 = no limit) | MILLISECONDS |  |  |
| `MAX_JOIN_SIZE` | Max Join Size (row combinations) | NA |  |  |
| `MAX_PREPARED_STMT_COUNT` | Max Prepared Statements (limit) | NA |  |  |
| `MAX_SP_RECURSION_DEPTH` | Max SP Recursion Depth (levels) | NA |  |  |
| `MAX_WRITE_LOCK_COUNT` | Max Write Lock Count (locks) | NA |  |  |
| `NOTES` | Notes | NA |  |  |
| `QUOTE_SHOW_CREATE` | Quote Show Create | NA |  |  |
| `SAFE_UPDATES` | Safe Updates | NA |  |  |
| `SELECT_LIMIT` | Select Limit (rows) | NA |  |  |
| `TEMPTABLE_MAX_RAM` | TempTable Max RAM (bytes) | BYTE |  |  |
| `WARNINGS` | Warnings | NA |  |  |

### Statement Processing (`StatementProcessingLive`) — collected on demand

Real-time mirror of the Statement Processing configuration snapshot — the same statement-processing server variables, refreshed on demand instead of on the configuration schedule.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `AUTO_IS_NULL` | Auto Is Null | NA |  |  |
| `BIG_SELECTS` | Big Selects | NA |  |  |
| `BUFFER_RESULT` | Buffer Result | NA |  |  |
| `CTE_MAX_RECURSION_DEPTH` | CTE Max Recursion Depth (levels) | NA |  |  |
| `DIV_PRECISION_INCREMENT` | Division Precision Increment (digits) | NA |  |  |
| `GROUP_CONCAT_MAX_LEN` | Group Concat Max Length (bytes) | BYTE |  |  |
| `INTERNAL_TMP_MEM_STORAGE_ENG` | Internal Tmp Mem Storage Eng | NA |  |  |
| `MAX_DIGEST_LENGTH` | Max Digest Length (bytes) | BYTE |  |  |
| `MAX_ERROR_COUNT` | Max Error Count (messages) | NA |  |  |
| `MAX_EXECUTION_TIME` | Max Execution Time (ms; 0 = no limit) | MILLISECONDS |  |  |
| `MAX_JOIN_SIZE` | Max Join Size (row combinations) | NA |  |  |
| `MAX_PREPARED_STMT_COUNT` | Max Prepared Statements (limit) | NA |  |  |
| `MAX_SP_RECURSION_DEPTH` | Max SP Recursion Depth (levels) | NA |  |  |
| `MAX_WRITE_LOCK_COUNT` | Max Write Lock Count (locks) | NA |  |  |
| `NOTES` | Notes | NA |  |  |
| `QUOTE_SHOW_CREATE` | Quote Show Create | NA |  |  |
| `SAFE_UPDATES` | Safe Updates | NA |  |  |
| `SELECT_LIMIT` | Select Limit (rows) | NA |  |  |
| `TEMPTABLE_MAX_RAM` | TempTable Max RAM (bytes) | BYTE |  |  |
| `WARNINGS` | Warnings | NA |  |  |

### MyISAM (`Myisam`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's MyISAM settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `CONCURRENT_INSERT` | Concurrent Insert | NA |  |  |
| `DELAY_KEY_WRITE` | Delay Key Write | NA |  |  |
| `KEEP_FILES_ON_CREATE` | Keep Files On Create | NA |  |  |
| `KEY_BUFFER_SIZE` | Key Buffer Size (bytes) | BYTE |  |  |
| `KEY_CACHE_AGE_THRESHOLD` | Key Cache Age Threshold (setting) | NA |  |  |
| `KEY_CACHE_BLOCK_SIZE` | Key Cache Block Size (bytes) | BYTE |  |  |
| `KEY_CACHE_DIVISION_LIMIT` | Key Cache Division Limit (% warm sublist) | PERCENTAGE |  |  |
| `MYISAM_DATA_POINTER_SIZE` | MyISAM Data Pointer Size (bytes) | BYTE |  |  |
| `MYISAM_MAX_SORT_FILE_SIZE` | MyISAM Max Sort File Size (bytes) | BYTE |  |  |
| `MYISAM_MMAP_SIZE` | MyISAM Mmap Size (bytes) | BYTE |  |  |
| `MYISAM_RECOVER_OPTIONS` | Myisam Recover Options | NA |  |  |
| `MYISAM_SORT_BUFFER_SIZE` | MyISAM Sort Buffer Size (bytes) | BYTE |  |  |
| `MYISAM_STATS_METHOD` | Myisam Stats Method | NA |  |  |
| `MYISAM_USE_MMAP` | Myisam Use Mmap | NA |  |  |
| `SKIP_EXTERNAL_LOCKING` | Skip External Locking | NA |  |  |

### MyISAM Full-Text (`MyisamFullText`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's MyISAM Full-Text settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BOOLEAN_SYNTAX` | Boolean Syntax | NA |  |  |
| `MAX_WORD_LEN` | Max Word Length (characters) | NA |  |  |
| `MIN_WORD_LEN` | Min Word Length (characters) | NA |  |  |
| `QUERY_EXPANSION_LIMIT` | Query Expansion Limit (rows) | NA |  |  |
| `STOPWORD_FILE` | Stopword File | NA |  |  |

### Table Configuration (`TableConfiguration`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Table Configuration settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BIG_TABLES` | Big Tables | NA |  |  |
| `DEFAULT_STORAGE_ENGINE` | Default Storage Engine | NA |  |  |
| `DEFAULT_TMP_STORAGE_ENGINE` | Default Tmp Storage Engine | NA |  |  |
| `EXPLICIT_DEFAULT_FOR_TS` | Explicit Default For Ts | NA |  |  |
| `FLUSH` | Flush | NA |  |  |
| `FLUSH_TIME` | Flush Time (s) | SECOND |  |  |
| `LOCK_WAIT_TIMEOUT` | Lock Wait Timeout (s) | SECOND |  |  |
| `LOWER_CASE_FILE_SYSTEM` | Lower Case File System | NA |  |  |
| `LOWER_CASE_TABLE_NAMES` | Lower Case Table Names (0 \| 1 \| 2) | NA |  |  |
| `LOW_PRIORITY_UPDATES` | Low Priority Updates | NA |  |  |
| `MAX_HEAP_TABLE_SIZE` | Max Heap Table Size (bytes) | BYTE |  |  |
| `OLD_ALTER_TABLE` | Old Alter Table | NA |  |  |
| `OPEN_FILES_LIMIT` | Open Files Limit (files) | NA |  |  |
| `TABLE_DEFINITION_CACHE` | Table Definition Cache (tables) | NA |  |  |
| `TABLE_OPEN_CACHE` | Table Open Cache (tables) | NA |  |  |
| `TABLE_OPEN_CACHE_INSTANCES` | Table Open Cache Instances (instances) | NA |  |  |
| `TMP_TABLE_SIZE` | Tmp Table Size (bytes) | BYTE |  |  |
| `UPDATABLE_VIEWS_WITH_LIMIT` | Updatable Views With Limit | NA |  |  |

### Table Configuration (`TableConfigurationLive`) — collected on demand

Real-time mirror of the Table Configuration configuration snapshot — the same table-handling server variables, refreshed on demand instead of on the configuration schedule.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BIG_TABLES` | Big Tables | NA |  |  |
| `DEFAULT_STORAGE_ENGINE` | Default Storage Engine | NA |  |  |
| `DEFAULT_TMP_STORAGE_ENGINE` | Default Tmp Storage Engine | NA |  |  |
| `EXPLICIT_DEFAULT_FOR_TS` | Explicit Default For Ts | NA |  |  |
| `FLUSH` | Flush | NA |  |  |
| `FLUSH_TIME` | Flush Time (s) | SECOND |  |  |
| `LOCK_WAIT_TIMEOUT` | Lock Wait Timeout (s) | SECOND |  |  |
| `LOWER_CASE_FILE_SYSTEM` | Lower Case File System | NA |  |  |
| `LOWER_CASE_TABLE_NAMES` | Lower Case Table Names (0 \| 1 \| 2) | NA |  |  |
| `LOW_PRIORITY_UPDATES` | Low Priority Updates | NA |  |  |
| `MAX_HEAP_TABLE_SIZE` | Max Heap Table Size (bytes) | BYTE |  |  |
| `OLD_ALTER_TABLE` | Old Alter Table | NA |  |  |
| `OPEN_FILES_LIMIT` | Open Files Limit (files) | NA |  |  |
| `TABLE_DEFINITION_CACHE` | Table Definition Cache (tables) | NA |  |  |
| `TABLE_OPEN_CACHE` | Table Open Cache (tables) | NA |  |  |
| `TABLE_OPEN_CACHE_INSTANCES` | Table Open Cache Instances (instances) | NA |  |  |
| `TMP_TABLE_SIZE` | Tmp Table Size (bytes) | BYTE |  |  |
| `UPDATABLE_VIEWS_WITH_LIMIT` | Updatable Views With Limit | NA |  |  |

### Collation (`Collation`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Collation settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `CONN` | Conn | NA |  |  |
| `DATABASE` | Database | NA |  |  |
| `SERVER_DEFAULT` | Server Default | NA |  |  |

### Localization (`Localization`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Localization settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `DEFAULT_WEEK_FORMAT` | Default Week Format (mode 0-7) | NA |  |  |
| `MESSAGES` | Messages | NA |  |  |
| `MESSAGES_DIR` | Messages Dir | NA |  |  |
| `SYSTEM_TIME_ZONE` | System Time Zone | NA |  |  |
| `TIME_NAMES` | Time Names | NA |  |  |
| `TIME_ZONE` | Time Zone | NA |  |  |

### InnoDB Configuration (`InnodbConfiguration`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's InnoDB Configuration settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ADAPTIVE_FLUSHING` | Adaptive Flushing | NA |  |  |
| `ADAPTIVE_FLUSHING_LWM` | Adaptive Flushing Low Water Mark (% of redo) | PERCENTAGE |  |  |
| `ADAPTIVE_HASH_INDEX` | Adaptive Hash Index | NA |  |  |
| `ADAPTIVE_MAX_SLEEP_DELAY` | Adaptive Max Sleep Delay (us) | MICROSEC |  |  |
| `AUTOEXTEND_INCREMENT` | Autoextend Increment (MB) | MB |  |  |
| `AUTOINC_LOCK_MODE` | Autoinc Lock Mode (0 trad. \| 1 consec. \| 2 interleaved) | NA |  |  |
| `BUFFER_POOL_CHUNK_SIZE` | Buffer Pool Chunk Size (bytes) | BYTE |  |  |
| `BUFFER_POOL_DUMP_AT_SHUTDOWN` | Buffer Pool Dump At Shutdown | NA |  |  |
| `BUFFER_POOL_DUMP_NOW` | Buffer Pool Dump Now | NA |  |  |
| `BUFFER_POOL_DUMP_PCT` | Buffer Pool Dump (% of pages) | PERCENTAGE |  |  |
| `BUFFER_POOL_FILENAME` | Buffer Pool Filename | NA |  |  |
| `BUFFER_POOL_INSTANCES` | Buffer Pool Instances (count) | NA |  |  |
| `BUFFER_POOL_LOAD_AT_STARTUP` | Buffer Pool Load At Startup | NA |  |  |
| `BUFFER_POOL_LOAD_NOW` | Buffer Pool Load Now | NA |  |  |
| `BUFFER_POOL_SIZE` | Buffer Pool Size (bytes) | BYTE |  |  |
| `CHANGE_BUFFERING` | Change Buffering | NA |  |  |
| `CHANGE_BUFFER_MAX_SIZE` | Change Buffer Max Size (% of buffer pool) | PERCENTAGE |  |  |
| `CHECKSUM_ALGORITHM` | Checksum Algorithm | NA |  |  |
| `COMMIT_CONCURRENCY` | Commit Concurrency (threads) | NA |  |  |
| `COMPRESSION_LEVEL` | Compression Level (0-9 zlib) | NA |  |  |
| `COMPRESSION_PAD_PCT_MAX` | Compression Pad Max (% of page) | PERCENTAGE |  |  |
| `CONCURRENCY_TICKETS` | Concurrency Tickets (tickets) | NA |  |  |
| `DATA_FILE_PATH` | Data File Path | NA |  |  |
| `DATA_HOME_DIR` | Data Home Dir | NA |  |  |
| `DEDICATED_SERVER` | Dedicated Server | NA |  |  |
| `DISABLE_SORT_FILE_CACHE` | Disable Sort File Cache | NA |  |  |
| `DOUBLEWRITE` | Doublewrite | NA |  |  |
| `FAST_SHUTDOWN` | Fast Shutdown (0 slow \| 1 fast \| 2 crash-like) | NA |  |  |
| `FILE_PER_TABLE` | File Per Table | NA |  |  |
| `FILL_FACTOR` | Fill Factor (% of page) | PERCENTAGE |  |  |
| `FLUSHING_AVG_LOOPS` | Flushing Avg Loops (iterations) | NA |  |  |
| `FLUSH_LOG_AT_TIMEOUT` | Flush Log At Timeout (s) | SECOND |  |  |
| `FLUSH_LOG_AT_TRX_COMMIT` | Flush Log at Trx Commit (0 \| 1 \| 2) | NA |  |  |
| `FLUSH_METHOD` | Flush Method | NA |  |  |
| `FLUSH_NEIGHBORS` | Flush Neighbors (0 off \| 1 contiguous \| 2 all) | NA |  |  |
| `FORCE_LOAD_CORRUPTED` | Force Load Corrupted | NA |  |  |
| `FORCE_RECOVERY` | Force Recovery (0 = off \| 1-6 = recovery level) | NA |  |  |
| `FOREIGN_KEY_CHECKS` | Foreign Key Checks | NA |  |  |
| `IO_CAPACITY` | I/O Capacity (IOPS) | IOSEC |  |  |
| `IO_CAPACITY_MAX` | I/O Capacity Max (IOPS) | IOSEC |  |  |
| `LOCK_WAIT_TIMEOUT` | Lock Wait Timeout (s) | SECOND |  |  |
| `LOG_BUFFER_SIZE` | Log Buffer Size (bytes) | BYTE |  |  |
| `LOG_COMPRESSED_PAGES` | Log Compressed Pages | NA |  |  |
| `LOG_FILES_IN_GROUP` | Log Files In Group (files) | NA |  |  |
| `LOG_FILE_SIZE` | Log File Size (bytes) | BYTE |  |  |
| `LOG_GROUP_HOME_DIR` | Log Group Home Dir | NA |  |  |
| `LOG_WRITE_AHEAD_SIZE` | Log Write Ahead Size (bytes) | BYTE |  |  |
| `LRU_SCAN_DEPTH` | LRU Scan Depth (pages) | NA |  |  |
| `MAX_DIRTY_PAGES_PCT` | Max Dirty Pages (%) | PERCENTAGE |  |  |
| `MAX_DIRTY_PAGES_PCT_LWM` | Max Dirty Pages Low Water Mark (%) | PERCENTAGE |  |  |
| `MAX_PURGE_LAG` | Max Purge Lag (history length) | NA |  |  |
| `MAX_PURGE_LAG_DELAY` | Max Purge Lag Delay (us) | MICROSEC |  |  |
| `MAX_UNDO_LOG_SIZE` | Max Undo Log Size (bytes) | BYTE |  |  |
| `MONITOR_DISABLE` | Monitor Disable | NA |  |  |
| `MONITOR_ENABLE` | Monitor Enable | NA |  |  |
| `MONITOR_RESET` | Monitor Reset | NA |  |  |
| `MONITOR_RESET_ALL` | Monitor Reset All | NA |  |  |
| `OLD_BLOCKS_PCT` | Old Blocks (% of buffer pool) | PERCENTAGE |  |  |
| `OLD_BLOCKS_TIME` | Old Blocks Time (ms) | MILLISECONDS |  |  |
| `ONLINE_ALTER_LOG_MAX_SIZE` | Online Alter Log Max Size (bytes) | BYTE |  |  |
| `OPEN_FILES` | Open Files (files) | NA |  |  |
| `PAGE_CLEANERS` | Page Cleaners (threads) | NA |  |  |
| `PAGE_SIZE` | Page Size (bytes) | BYTE |  |  |
| `PRINT_ALL_DEADLOCKS` | Print All Deadlocks | NA |  |  |
| `PRINT_DDL_LOGS` | Print Ddl Logs | NA |  |  |
| `PURGE_BATCH_SIZE` | Purge Batch Size (undo pages) | NA |  |  |
| `PURGE_RSEG_TRUNCATE_FREQUENCY` | Purge Rseg Truncate Frequency (purges) | NA |  |  |
| `PURGE_THREADS` | Purge Threads (threads) | NA |  |  |
| `RANDOM_READ_AHEAD` | Random Read Ahead | NA |  |  |
| `READ_AHEAD_THRESHOLD` | Read Ahead Threshold (pages) | NA |  |  |
| `READ_IO_THREADS` | Read I/O Threads | NA |  |  |
| `READ_ONLY` | Read Only | NA |  |  |
| `REDO_LOG_ENCRYPT` | Redo Log Encrypt | NA |  |  |
| `ROLLBACK_ON_TIMEOUT` | Rollback On Timeout | NA |  |  |
| `SORT_BUFFER_SIZE` | Sort Buffer Size (bytes) | BYTE |  |  |
| `SPIN_WAIT_DELAY` | Spin Wait Delay (multiplier) | NA |  |  |
| `STATS_AUTO_RECALC` | Stats Auto Recalc | NA |  |  |
| `STATS_METHOD` | Stats Method | NA |  |  |
| `STATS_ON_METADATA` | Stats On Metadata | NA |  |  |
| `STATS_PERSISTENT` | Stats Persistent | NA |  |  |
| `STATS_PERSISTENT_SAMPLE_PAGES` | Stats Persistent Sample Pages (pages) | NA |  |  |
| `STRICT_MODE` | Strict Mode | NA |  |  |
| `SYNC_ARRAY_SIZE` | Sync Array Size (arrays) | NA |  |  |
| `SYNC_SPIN_LOOPS` | Sync Spin Loops (iterations) | NA |  |  |
| `TABLE_LOCKS` | Table Locks | NA |  |  |
| `TEMP_DATA_FILE_PATH` | Temp Data File Path | NA |  |  |
| `THREAD_CONCURRENCY` | Thread Concurrency (threads) | NA |  |  |
| `THREAD_SLEEP_DELAY` | Thread Sleep Delay (us) | MICROSEC |  |  |
| `UNDO_DIRECTORY` | Undo Directory | NA |  |  |
| `UNDO_LOG_ENCRYPT` | Undo Log Encrypt | NA |  |  |
| `UNDO_LOG_TRUNCATE` | Undo Log Truncate | NA |  |  |
| `UNDO_TABLESPACES` | Undo Tablespaces (count) | NA |  |  |
| `UNIQUE_CHECKS` | Unique Checks | NA |  |  |
| `USE_NATIVE_AIO` | Use Native Aio | NA |  |  |
| `WRITE_IO_THREADS` | Write I/O Threads | NA |  |  |

### InnoDB Configuration (`InnodbConfigurationLive`) — collected on demand

Real-time mirror of the InnoDB Configuration configuration snapshot — the same InnoDB server variables, refreshed on demand instead of on the configuration schedule.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ADAPTIVE_FLUSHING` | Adaptive Flushing | NA |  |  |
| `ADAPTIVE_FLUSHING_LWM` | Adaptive Flushing Low Water Mark (% of redo) | PERCENTAGE |  |  |
| `ADAPTIVE_HASH_INDEX` | Adaptive Hash Index | NA |  |  |
| `ADAPTIVE_MAX_SLEEP_DELAY` | Adaptive Max Sleep Delay (us) | MICROSEC |  |  |
| `AUTOEXTEND_INCREMENT` | Autoextend Increment (MB) | MB |  |  |
| `AUTOINC_LOCK_MODE` | Autoinc Lock Mode (0 trad. \| 1 consec. \| 2 interleaved) | NA |  |  |
| `BUFFER_POOL_CHUNK_SIZE` | Buffer Pool Chunk Size (bytes) | BYTE |  |  |
| `BUFFER_POOL_DUMP_AT_SHUTDOWN` | Buffer Pool Dump At Shutdown | NA |  |  |
| `BUFFER_POOL_DUMP_NOW` | Buffer Pool Dump Now | NA |  |  |
| `BUFFER_POOL_DUMP_PCT` | Buffer Pool Dump (% of pages) | PERCENTAGE |  |  |
| `BUFFER_POOL_FILENAME` | Buffer Pool Filename | NA |  |  |
| `BUFFER_POOL_INSTANCES` | Buffer Pool Instances (count) | NA |  |  |
| `BUFFER_POOL_LOAD_AT_STARTUP` | Buffer Pool Load At Startup | NA |  |  |
| `BUFFER_POOL_LOAD_NOW` | Buffer Pool Load Now | NA |  |  |
| `BUFFER_POOL_SIZE` | Buffer Pool Size (bytes) | BYTE |  |  |
| `CHANGE_BUFFERING` | Change Buffering | NA |  |  |
| `CHANGE_BUFFER_MAX_SIZE` | Change Buffer Max Size (% of buffer pool) | PERCENTAGE |  |  |
| `CHECKSUM_ALGORITHM` | Checksum Algorithm | NA |  |  |
| `COMMIT_CONCURRENCY` | Commit Concurrency (threads) | NA |  |  |
| `COMPRESSION_LEVEL` | Compression Level (0-9 zlib) | NA |  |  |
| `COMPRESSION_PAD_PCT_MAX` | Compression Pad Max (% of page) | PERCENTAGE |  |  |
| `CONCURRENCY_TICKETS` | Concurrency Tickets (tickets) | NA |  |  |
| `DATA_FILE_PATH` | Data File Path | NA |  |  |
| `DATA_HOME_DIR` | Data Home Dir | NA |  |  |
| `DEDICATED_SERVER` | Dedicated Server | NA |  |  |
| `DISABLE_SORT_FILE_CACHE` | Disable Sort File Cache | NA |  |  |
| `DOUBLEWRITE` | Doublewrite | NA |  |  |
| `FAST_SHUTDOWN` | Fast Shutdown (0 slow \| 1 fast \| 2 crash-like) | NA |  |  |
| `FILE_PER_TABLE` | File Per Table | NA |  |  |
| `FILL_FACTOR` | Fill Factor (% of page) | PERCENTAGE |  |  |
| `FLUSHING_AVG_LOOPS` | Flushing Avg Loops (iterations) | NA |  |  |
| `FLUSH_LOG_AT_TIMEOUT` | Flush Log At Timeout (s) | SECOND |  |  |
| `FLUSH_LOG_AT_TRX_COMMIT` | Flush Log at Trx Commit (0 \| 1 \| 2) | NA |  |  |
| `FLUSH_METHOD` | Flush Method | NA |  |  |
| `FLUSH_NEIGHBORS` | Flush Neighbors (0 off \| 1 contiguous \| 2 all) | NA |  |  |
| `FORCE_LOAD_CORRUPTED` | Force Load Corrupted | NA |  |  |
| `FORCE_RECOVERY` | Force Recovery (0 = off \| 1-6 = recovery level) | NA |  |  |
| `FOREIGN_KEY_CHECKS` | Foreign Key Checks | NA |  |  |
| `IO_CAPACITY` | I/O Capacity (IOPS) | IOSEC |  |  |
| `IO_CAPACITY_MAX` | I/O Capacity Max (IOPS) | IOSEC |  |  |
| `LOCK_WAIT_TIMEOUT` | Lock Wait Timeout (s) | SECOND |  |  |
| `LOG_BUFFER_SIZE` | Log Buffer Size (bytes) | BYTE |  |  |
| `LOG_COMPRESSED_PAGES` | Log Compressed Pages | NA |  |  |
| `LOG_FILES_IN_GROUP` | Log Files In Group (files) | NA |  |  |
| `LOG_FILE_SIZE` | Log File Size (bytes) | BYTE |  |  |
| `LOG_GROUP_HOME_DIR` | Log Group Home Dir | NA |  |  |
| `LOG_WRITE_AHEAD_SIZE` | Log Write Ahead Size (bytes) | BYTE |  |  |
| `LRU_SCAN_DEPTH` | LRU Scan Depth (pages) | NA |  |  |
| `MAX_DIRTY_PAGES_PCT` | Max Dirty Pages (%) | PERCENTAGE |  |  |
| `MAX_DIRTY_PAGES_PCT_LWM` | Max Dirty Pages Low Water Mark (%) | PERCENTAGE |  |  |
| `MAX_PURGE_LAG` | Max Purge Lag (history length) | NA |  |  |
| `MAX_PURGE_LAG_DELAY` | Max Purge Lag Delay (us) | MICROSEC |  |  |
| `MAX_UNDO_LOG_SIZE` | Max Undo Log Size (bytes) | BYTE |  |  |
| `MONITOR_DISABLE` | Monitor Disable | NA |  |  |
| `MONITOR_ENABLE` | Monitor Enable | NA |  |  |
| `MONITOR_RESET` | Monitor Reset | NA |  |  |
| `MONITOR_RESET_ALL` | Monitor Reset All | NA |  |  |
| `OLD_BLOCKS_PCT` | Old Blocks (% of buffer pool) | PERCENTAGE |  |  |
| `OLD_BLOCKS_TIME` | Old Blocks Time (ms) | MILLISECONDS |  |  |
| `ONLINE_ALTER_LOG_MAX_SIZE` | Online Alter Log Max Size (bytes) | BYTE |  |  |
| `OPEN_FILES` | Open Files (files) | NA |  |  |
| `PAGE_CLEANERS` | Page Cleaners (threads) | NA |  |  |
| `PAGE_SIZE` | Page Size (bytes) | BYTE |  |  |
| `PRINT_ALL_DEADLOCKS` | Print All Deadlocks | NA |  |  |
| `PRINT_DDL_LOGS` | Print Ddl Logs | NA |  |  |
| `PURGE_BATCH_SIZE` | Purge Batch Size (undo pages) | NA |  |  |
| `PURGE_RSEG_TRUNCATE_FREQUENCY` | Purge Rseg Truncate Frequency (purges) | NA |  |  |
| `PURGE_THREADS` | Purge Threads (threads) | NA |  |  |
| `RANDOM_READ_AHEAD` | Random Read Ahead | NA |  |  |
| `READ_AHEAD_THRESHOLD` | Read Ahead Threshold (pages) | NA |  |  |
| `READ_IO_THREADS` | Read I/O Threads | NA |  |  |
| `READ_ONLY` | Read Only | NA |  |  |
| `REDO_LOG_ENCRYPT` | Redo Log Encrypt | NA |  |  |
| `ROLLBACK_ON_TIMEOUT` | Rollback On Timeout | NA |  |  |
| `SORT_BUFFER_SIZE` | Sort Buffer Size (bytes) | BYTE |  |  |
| `SPIN_WAIT_DELAY` | Spin Wait Delay (multiplier) | NA |  |  |
| `STATS_AUTO_RECALC` | Stats Auto Recalc | NA |  |  |
| `STATS_METHOD` | Stats Method | NA |  |  |
| `STATS_ON_METADATA` | Stats On Metadata | NA |  |  |
| `STATS_PERSISTENT` | Stats Persistent | NA |  |  |
| `STATS_PERSISTENT_SAMPLE_PAGES` | Stats Persistent Sample Pages (pages) | NA |  |  |
| `STRICT_MODE` | Strict Mode | NA |  |  |
| `SYNC_ARRAY_SIZE` | Sync Array Size (arrays) | NA |  |  |
| `SYNC_SPIN_LOOPS` | Sync Spin Loops (iterations) | NA |  |  |
| `TABLE_LOCKS` | Table Locks | NA |  |  |
| `TEMP_DATA_FILE_PATH` | Temp Data File Path | NA |  |  |
| `THREAD_CONCURRENCY` | Thread Concurrency (threads) | NA |  |  |
| `THREAD_SLEEP_DELAY` | Thread Sleep Delay (us) | MICROSEC |  |  |
| `UNDO_DIRECTORY` | Undo Directory | NA |  |  |
| `UNDO_LOG_ENCRYPT` | Undo Log Encrypt | NA |  |  |
| `UNDO_LOG_TRUNCATE` | Undo Log Truncate | NA |  |  |
| `UNDO_TABLESPACES` | Undo Tablespaces (count) | NA |  |  |
| `UNIQUE_CHECKS` | Unique Checks | NA |  |  |
| `USE_NATIVE_AIO` | Use Native Aio | NA |  |  |
| `WRITE_IO_THREADS` | Write I/O Threads | NA |  |  |

### Performance Schema (`PerformanceSchema`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Performance Schema settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ACCOUNTS_SIZE` | Accounts Size (rows) | NA |  |  |
| `DIGESTS_SIZE` | Digests Size (rows) | NA |  |  |
| `ENABLED` | Enabled | NA |  |  |
| `ERROR_SIZE` | Error Size (error codes) | NA |  |  |
| `STAGES_HISTORY_LONG_SIZE` | Stages History Long Size (rows) | NA |  |  |
| `EVENTS_STAGES_HISTORY_SIZE` | Events Stages History Size (rows/thread) | NA |  |  |
| `STMTS_HISTORY_LONG_SIZE` | Statements History Long Size (rows) | NA |  |  |
| `EVENTS_STMTS_HISTORY_SIZE` | Events Statements History Size (rows/thread) | NA |  |  |
| `EVENTS_TRXS_HISTORY_LONG_SIZE` | Transactions History Long Size (rows) | NA |  |  |
| `EVENTS_TRXS_HISTORY_SIZE` | Events Transactions History Size (rows/thread) | NA |  |  |
| `EVENTS_WAITS_HISTORY_LONG_SIZE` | Waits History Long Size (rows) | NA |  |  |
| `EVENTS_WAITS_HISTORY_SIZE` | Events Waits History Size (rows/thread) | NA |  |  |
| `HOSTS_SIZE` | Hosts Size (rows) | NA |  |  |
| `MAX_COND_CLASSES` | Max Condition Classes (limit) | NA |  |  |
| `MAX_COND_INSTANCES` | Max Condition Instances (limit) | NA |  |  |
| `MAX_DIGEST_LENGTH` | Max Digest Length (bytes) | BYTE |  |  |
| `MAX_DIGEST_SAMPLE_AGE` | Max Digest Sample Age (s) | SECOND |  |  |
| `MAX_FILE_CLASSES` | Max File Classes (limit) | NA |  |  |
| `MAX_FILE_HANDLES` | Max File Handles (limit) | NA |  |  |
| `MAX_FILE_INSTANCES` | Max File Instances (limit) | NA |  |  |
| `MAX_INDEX_STAT` | Max Index Stat (indexes) | NA |  |  |
| `MAX_MEMORY_CLASSES` | Max Memory Classes (limit) | NA |  |  |
| `MAX_METADATA_LOCKS` | Max Metadata Locks (locks) | NA |  |  |
| `MAX_MUTEX_CLASSES` | Max Mutex Classes (limit) | NA |  |  |
| `MAX_MUTEX_INSTANCES` | Max Mutex Instances (limit) | NA |  |  |
| `MAX_PREPARED_STMTS_INSTANCES` | Max Prepared Statement Instances (limit) | NA |  |  |
| `MAX_PROGRAM_INSTANCES` | Max Program Instances (limit) | NA |  |  |
| `MAX_RWLOCK_CLASSES` | Max RWLock Classes (limit) | NA |  |  |
| `MAX_RWLOCK_INSTANCES` | Max RWLock Instances (limit) | NA |  |  |
| `MAX_SOCKET_CLASSES` | Max Socket Classes (limit) | NA |  |  |
| `MAX_SOCKET_INSTANCES` | Max Socket Instances (limit) | NA |  |  |
| `MAX_SQL_TEXT_LENGTH` | Max SQL Text Length (bytes) | BYTE |  |  |
| `MAX_STAGE_CLASSES` | Max Stage Classes (limit) | NA |  |  |
| `MAX_STMT_CLASSES` | Max Statement Classes (limit) | NA |  |  |
| `MAX_STMT_STACK` | Max Statement Stack (levels) | NA |  |  |
| `MAX_TABLE_HANDLES` | Max Table Handles (limit) | NA |  |  |
| `MAX_TABLE_INSTANCES` | Max Table Instances (limit) | NA |  |  |
| `MAX_TABLE_LOCK_STAT` | Max Table Lock Stat (tables) | NA |  |  |
| `MAX_THREAD_CLASSES` | Max Thread Classes (limit) | NA |  |  |
| `MAX_THREAD_INSTANCES` | Max Thread Instances (limit) | NA |  |  |
| `SESSION_CONNECT_ATTRS_SIZE` | Session Connect Attrs Size (bytes) | BYTE |  |  |
| `SETUP_ACTORS_SIZE` | Setup Actors Size (rows) | NA |  |  |
| `SETUP_OBJECTS_SIZE` | Setup Objects Size (rows) | NA |  |  |
| `USERS_SIZE` | Users Size (rows) | NA |  |  |

### Capabilities (`Capabilities`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Capabilities settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `CAPABILITIES_COMPRESS` | Capabilities Compress | NA |  |  |
| `DYNAMIC_LOADING` | Dynamic Loading | NA |  |  |
| `GEOMETRY_TYPES` | Geometry Types | NA |  |  |
| `PROFILING` | Profiling | NA |  |  |
| `QUERY_CACHE` | Query Cache | NA |  |  |
| `RTREE_KEYS` | Rtree Keys | NA |  |  |
| `STMT_TIMEOUT` | Stmt Timeout | NA |  |  |
| `SYMLINK` | Symlink | NA |  |  |
| `EVENT_SCHEDULER` | Event Scheduler | NA |  |  |

### Binary Log Status (`BinaryLogStatus`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Binary Log Status settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BINLOG_DO_DB` | Binlog Do DB | NA |  |  |
| `BINLOG_IGNORE_DB` | Binlog Ignore DB | NA |  |  |

### Security (`Security`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Security settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ACTIVATE_ALL_ROLES_ON_LOGIN` | Activate All Roles On Login | NA |  |  |
| `AUTO_GENERATE_CERTS` | Auto Generate Certs | NA |  |  |
| `AUTOMATIC_SP_PRIVILEGES` | Automatic Sp Privileges | NA |  |  |
| `CACHING_SHA2_PASS_PRIVKEY_PATH` | Caching Sha2 Pass Privkey Path | NA |  |  |
| `CACHING_SHA2_PASS_PUBKEY_PATH` | Caching Sha2 Pass Pubkey Path | NA |  |  |
| `CHECK_PROXY_USERS` | Check Proxy Users | NA |  |  |
| `DEFAULT_PASSWORD_LIFETIME` | Default Password Lifetime (days; 0 = never) | DAYS |  |  |
| `DISCONNECT_ON_EXPIRED_PASSWORD` | Disconnect On Expired Password | NA |  |  |
| `LOCAL_INFILE` | Local Infile | NA |  |  |
| `MANDATORY_ROLES` | Mandatory Roles | NA |  |  |
| `MYSQL_NATIVE_PW_PROXY_USERS` | Mysql Native Pw Proxy Users | NA |  |  |
| `PASSWORD_HISTORY` | Password History (passwords) | NA |  |  |
| `PASSWORD_REUSE_INTERVAL` | Password Reuse Interval (days; 0 = none) | DAYS |  |  |
| `SECURE_FILE_PRIVILEGES` | Secure File Privileges | NA |  |  |
| `SHA256_PW_AUTO_GEN_RSA_KEYS` | Sha256 Pw Auto Gen Rsa Keys | NA |  |  |
| `SHA256_PW_PRIVATE_KEY_PATH` | Sha256 Pw Private Key Path | NA |  |  |
| `SHA256_PASSWORD_PROXY_USERS` | Sha256 Password Proxy Users | NA |  |  |
| `SHA256_PW_PUBLIC_KEY_PATH` | Sha256 Pw Public Key Path | NA |  |  |
| `SKIP_SHOW_DATABASE` | Skip Show Database | NA |  |  |
| `AUTHENTICATION_POLICY` | Authentication Policy | NA |  |  |

### Password Validation (`PasswordValidation`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Password Validation settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `DICTIONARY_FILE` | Dictionary File | NA |  |  |
| `LENGTH` | Min Password Length (characters) | NA |  |  |
| `MIXED_CASE_COUNT` | Min Mixed-Case Characters (each case) | NA |  |  |
| `NUMBER_COUNT` | Min Digits | NA |  |  |
| `POLICY` | Policy | NA |  |  |
| `SPECIAL_CHAR_COUNT` | Min Special Characters | NA |  |  |

### Security Accounts (`SecurityAccounts`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Security Accounts settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `USER_HOST` (key) | User Host | NA |  |  |
| `USER_NAME` | User | NA |  |  |
| `HOST` | Host | NA |  |  |
| `AUTH_PLUGIN` | Auth Plugin | NA |  |  |
| `ACCOUNT_LOCKED` | Account Locked (0/1: 1 = locked) | NA |  |  |
| `IS_ANONYMOUS` | Anonymous Account (0/1: 1 = empty user name) | NA |  |  |
| `IS_REMOTE_ROOT` | Remote Root (0/1: 1 = root from a non-local host) | NA |  |  |
| `HAS_ALL_PRIVILEGES` | Has All Privileges (0/1: 1 = every static privilege) | NA |  |  |
| `HAS_GRANT_OPTION` | Has Grant Option (0/1: 1 = can grant privileges) | NA |  |  |
| `HAS_FILE_PRIV` | Has FILE Privilege (0/1: 1 = yes) | NA |  |  |
| `HAS_PROCESS_PRIV` | Has PROCESS Privilege (0/1: 1 = yes) | NA |  |  |
| `HAS_SHUTDOWN_PRIV` | Has SHUTDOWN Privilege (0/1: 1 = yes) | NA |  |  |
| `HAS_SUPER_PRIV` | Has SUPER Privilege (0/1: 1 = SUPER or equivalent) | NA |  |  |
| `HAS_MYSQL_SCHEMA_WRITE` | Has mysql Schema Write (0/1: 1 = can write) | NA |  |  |
| `HAS_EMPTY_PASSWORD` | Has Empty Password (0/1: 1 = empty password) | NA |  |  |
| `HAS_LOGIN_LOCKOUT` | Has Login Lockout (0/1: 1 = lockout configured) | NA |  |  |

### Security Config Ext (`SecurityConfigExt`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Security Config Ext settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `PARTIAL_REVOKES` | Partial Revokes | NA |  |  |
| `BINLOG_ENCRYPTION` | Binlog Encryption | NA |  |  |
| `DEFAULT_TABLE_ENCRYPTION` | Default Table Encryption | NA |  |  |
| `AUDIT_LOG_ENCRYPTION` | Audit Log Encryption | NA |  |  |
| `KEYRING_AVAILABLE` | Keyring Available (0/1: 1 = plugin or component active) | NA |  |  |
| `CONNECTION_CONTROL_INSTALLED` | Connection Control Installed (0/1: 1 = plugin active) | NA |  |  |

### InnoDB Fulltext (`InnodbFulltext`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's InnoDB Fulltext settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `AUX_TABLE` | Aux Table | NA |  |  |
| `CACHE_SIZE` | FT Cache Size (bytes) | BYTE |  |  |
| `ENABLE_DIAG_PRINT` | Enable Diag Print | NA |  |  |
| `ENABLE_STOPWORD` | Enable Stopword | NA |  |  |
| `MAX_TOKEN_SIZE` | FT Max Token Size (characters) | NA |  |  |
| `MIN_TOKEN_SIZE` | FT Min Token Size (characters) | NA |  |  |
| `NUM_WORD_OPTIMIZE` | FT Words Per OPTIMIZE (words) | NA |  |  |
| `OPTIMIZE_FULLTEXT_ONLY` | Optimize Fulltext Only | NA |  |  |
| `RESULT_CACHE_LIMIT` | FT Result Cache Limit (bytes) | BYTE |  |  |
| `SERVER_STOPWORD_TABLE` | Server Stopword Table | NA |  |  |
| `SORT_PLL_DEGREE` | FT Sort Parallel Degree (threads) | NA |  |  |
| `TOTAL_CACHE_SIZE` | FT Total Cache Size (bytes) | BYTE |  |  |
| `USER_STOPWORD_TABLE` | User Stopword Table | NA |  |  |

### InnoDB Memcached Configuration (`InnodbMemcachedConfiguration`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's InnoDB Memcached Configuration settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `BK_COMMIT_INTERVAL` | Background Commit Interval (s) | SECOND |  |  |
| `DISABLE_ROWLOCK` | Disable Rowlock | NA |  |  |
| `ENABLE_BINLOG` | Enable Binlog | NA |  |  |
| `ENABLE_MDL` | Enable Mdl | NA |  |  |
| `ENGINE_LIB_NAME` | Engine Lib Name | NA |  |  |
| `ENGINE_LIB_PATH` | Engine Lib Path | NA |  |  |
| `OPTIONS` | Options | NA |  |  |
| `READ_BATCH_SIZE` | Read Batch Size (operations) | NA |  |  |
| `TRX_LEVEL` | Trx Isolation Level (0 \| 1 \| 2 \| 3) | NA |  |  |
| `WRITE_BATCH_SIZE` | Write Batch Size (operations) | NA |  |  |

### Insert Delayed (`InsertDelayed`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Insert Delayed settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `INSERT_LIMIT` | Insert Limit (rows) | NA |  |  |
| `INSERT_TIMEOUT` | Insert Timeout (s) | SECOND |  |  |
| `MAX_DELAYED_THREADS` | Max Delayed Threads (threads) | NA |  |  |
| `QUEUE_SIZE` | Queue Size (rows) | NA |  |  |

### NDB (`Ndb`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's NDB settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ENGINE_CONDITION_PUSHDOWN` | Engine Condition Pushdown | NA |  |  |
| `NDB_AUTOINC_PREFETCH` | Auto-Increment Prefetch (values) | NA |  |  |

### Thread Pool (`ThreadPool`) — configuration snapshot, collected every 24 Hr

Configuration snapshot of the server's Thread Pool settings, captured for configuration history and compliance evaluation.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ALGORITHM` | Algorithm (0 = low concurrency \| 1 = high concurrency) | NA |  |  |
| `HIGH_PRIORITY_CONN` | High Priority Connection (0/1: 1 = high priority) | NA |  |  |
| `MAX_UNUSED_THREADS` | Max Unused Threads (threads) | NA |  |  |
| `PRIO_KICKUP_TIMER` | Priority Kickup Timer (ms) | MILLISECONDS |  |  |
| `THREAD_POOL_SIZE` | Thread Pool Size (thread groups) | NA |  |  |
| `STALL_LIMIT` | Stall Limit (10 ms units) | NA |  |  |

### Wait Profile (Top Waits) (`WaitProfile`) — collected every 1 Min

Top wait events by time consumed during the collection interval, as deltas from performance_schema.events_waits_summary_global_by_event_name.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `event_name` (key) | Event Name | NA |  |  |
| `wait_class` | Wait Class | NA |  |  |
| `d_count` | Wait Count (since prev. collection, ~1 min) | NA |  |  |
| `d_time_us` | Wait Time (since prev. collection, ~1 min) | MICROSEC |  |  |
| `avg_wait_us` | Avg Wait (since prev. collection, ~1 min) | MICROSEC | > 1000000 | > 5000000 |

### Wait Profile Summary (`WaitProfileSummary`) — collected every 1 Min

Single-row summary of the interval's wait activity — total wait time, number of active wait events, and the single busiest wait event — rolled up from the Wait Profile data. An interval with no wait activity is reported explicitly (zero totals, top event and class `idle`); only the first collection after the agent starts reports nothing.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `total_wait_time_us` | Total Wait Time, all events (since prev. collection, ~1 min) | MICROSEC |  |  |
| `active_event_count` | Active Wait Events (since prev. collection, ~1 min) | NA |  |  |
| `top_wait_event` | Top Wait Event (since prev. collection, ~1 min) | NA |  |  |
| `top_wait_time_us` | Top Wait Time (since prev. collection, ~1 min) | MICROSEC |  |  |
| `top_wait_class` | Top Wait Class (since prev. collection, ~1 min) | NA | = lock |  |

### Query Analytics (Statement Digest Deltas) (`StatementDigestProfile`) — collected every 5 Min

Per-statement-digest execution deltas for the collection interval — execution count, latency, rows examined/sent, and index usage — from performance_schema.events_statements_summary_by_digest.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `digest` (key) | Statement Digest | NA |  |  |
| `d_exec_count` | Executions (since prev. collection, ~5 min) | NA |  |  |
| `d_total_latency_us` | Total Latency (since prev. collection, ~5 min) | MICROSEC |  |  |
| `d_avg_latency_us` | Average Latency (since prev. collection, ~5 min) | MICROSEC |  |  |
| `d_lock_time_us` | Lock Time (since prev. collection, ~5 min) | MICROSEC |  |  |
| `d_rows_examined` | Rows Examined (since prev. collection, ~5 min) | NA |  |  |
| `d_rows_sent` | Rows Sent (since prev. collection, ~5 min) | NA |  |  |
| `d_rows_examined_per_sent` | Rows Examined per Row Sent (ratio, since prev. collection) | NA |  |  |
| `d_no_index_used` | Executions Without an Index (since prev. coll., ~5 min) | NA |  |  |

### Query Analytics Summary (`StatementDigestProfileSummary`) — collected every 5 Min

Single-row summary of the interval's statement activity — total latency, total executions, number of active digests, and the single busiest digest — rolled up from the Statement Digest Profile data.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `total_latency_us` | Total Statement Latency, all digests, last 5 min | MICROSEC |  |  |
| `total_exec_count` | Total Executions, all digests, last 5 min | NA |  |  |
| `active_digest_count` | Active Statement Digests, last 5 min | NA |  |  |
| `top_digest` | Top Statement Digest, last 5 min | NA |  |  |
| `top_digest_latency_us` | Top Statement Latency, last 5 min | MICROSEC |  |  |
| `digest_overflow_active` | Digest Table Overflowing (0/1, 1 = overflowing) | NA |  |  |
| `digest_capacity_pct` | Digest Table Used (%) | PERCENTAGE |  |  |

### License (`License`) — collected every 15 Min

Licence state of this plug-in installation, not of the MySQL server — the collection contacts neither the database nor the OMS. Status carries the reason (Active, Expired, Wrong Plug-in, Invalid Signature or License Required); the alert is set on the licensed column, which is 1 only when the licence is active.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `status` | Status (Active \| Expired \| Invalid Signature \| ...) | NA |  |  |
| `licensed` | Licensed (0/1: 1 = licence is Active) | NA |  | < 1 |
| `days_remaining` | Days Remaining (perpetual if Never Expires = 1) | DAYS | < 30 | < 7 |
| `expiration` | Expiration | NA |  |  |
| `license_type` | Type (Trial \| Enterprise \| None \| ...) | NA |  |  |
| `instances` | Licensed Instances (entitlement) | NA |  |  |
| `customer` | Customer | NA |  |  |
| `never_expires` | Never Expires (0/1: 1 = perpetual licence) | NA |  |  |

### Monitoring Readiness Detail (`readiness_detail`) — collected on demand

Monitoring Readiness checks, one row per requirement, keyed by feature section and check — what each feature needs, what is in effect now, and a status of ok, warn, fail or unknown (unknown means the check could not be made, never a pass). It is probed live under the target's monitoring credentials each time the Monitoring Readiness page loads, not collected on a schedule, so nothing is stored and a change to the server shows on the next page load. Database targets are checked for the monitoring grants, performance_schema, the sys schema, a backup tool history and the plug-in licence; ClusterSet targets for the connection and for MySQL Shell on the agent host. A failed connection is a row, not an error. The page is read-only: the statement that would fix a check is in its Detail, and the plug-in never runs it.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `section` (key) | Feature Section | NA |  |  |
| `item` (key) | Check Id | NA |  |  |
| `database_name` | Database Name (blank: one scope per target) | NA |  |  |
| `label` | Requirement | NA |  |  |
| `mandatory` | Mandatory (0/1: 1 = required, 0 = optional) | NA |  |  |
| `required` | Required Value | NA |  |  |
| `current` | Current Value | NA |  |  |
| `status` | Status (ok \| warn \| fail \| unknown) | NA |  |  |
| `fixable` | Fixable by the Plug-in (0/1: always 0 in this release) | NA |  |  |
| `detail` | Detail and Suggested Fix | NA |  |  |

### Monitoring Readiness Summary (`readiness_summary`) — collected every 60 Min

Single-row rollup of the Monitoring Readiness checks for the Home page — how many features are ok, need attention (warn), are not functional (fail) or could not be checked (unknown). A feature is as bad as its worst check, and an optional check counts at most as a warning. No alert is set on it: readiness is a state to read, not a fault.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `ok_count` | Features Ready (count of ok features) | NA |  |  |
| `warn_count` | Features Needing Attention (count of warn) | NA |  |  |
| `fail_count` | Features Not Functional (count of fail) | NA |  |  |
| `unknown_count` | Features Not Checked (count of unknown) | NA |  |  |

### Table Storage (`TableStorage`) — collected every 60 Min

Table sizes for the Tables page — data, index, free space, estimated rows, engine and row format per table, from INFORMATION_SCHEMA.TABLES. One row for each of the 500 largest user tables, an /other/ row totalling the tables past the cap and a /system/ row totalling the mysql, sys, information_schema and performance_schema schemas, so a total built from the rows is complete. Collected hourly and kept as history: MySQL 8 caches these figures (information_schema_stats_expiry, one day by default), so row counts and sizes can lag recent changes, and run ANALYZE TABLE for fresh numbers. A size the server does not report is blank, never 0. No alert is set on it.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `table_schema` (key) | Schema | NA |  |  |
| `table_name` (key) | Table | NA |  |  |
| `row_kind` | Row Kind | NA |  |  |
| `table_count` | Tables in Row | NA |  |  |
| `total_bytes` | Total Size | BYTE |  |  |
| `data_bytes` | Data Size | BYTE |  |  |
| `index_bytes` | Index Size | BYTE |  |  |
| `data_free_bytes` | Free Space | BYTE |  |  |
| `row_estimate` | Estimated Rows | NA |  |  |
| `engine` | Engine | NA |  |  |
| `row_format` | Row Format | NA |  |  |
| `update_time` | Last Updated | NA |  |  |

### Index Storage (`IndexStorage`) — collected every 60 Min

Index sizes for the Indexes page — one row per index with its table, columns, uniqueness, primary-key flag, type and cardinality, from INFORMATION_SCHEMA.STATISTICS, capped like Table Storage (the 500 largest, an /other/ row and a /system/ row). The size is the InnoDB page count in mysql.innodb_index_stats times the server's innodb_page_size; MySQL exposes no size for other engines, for partitioned tables, for 5.7 tables whose names need file-name encoding, or when the account cannot read that table, and then the size is blank, not 0. A functional (expression) key part is listed by its expression, and a column list over 200 characters is cut and ends with "...". An InnoDB primary key is the table itself, so its size includes the rows. Collected hourly. No alert is set on it.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `table_schema` (key) | Schema | NA |  |  |
| `table_name` (key) | Table | NA |  |  |
| `index_name` (key) | Index | NA |  |  |
| `row_kind` | Row Kind | NA |  |  |
| `index_count` | Indexes in Row | NA |  |  |
| `size_bytes` | Size | BYTE |  |  |
| `cardinality` | Estimated Distinct Keys | NA |  |  |
| `is_unique` | Unique (0/1: 1 = enforces uniqueness) | NA |  |  |
| `is_primary` | Primary Key (0/1: 1 = the PRIMARY KEY) | NA |  |  |
| `index_type` | Index Type (BTREE\|HASH\|FULLTEXT\|SPATIAL) | NA |  |  |
| `index_columns` | Columns | NA |  |  |

### Index Summary (`IndexSummary`) — collected every 60 Min

Single-row figures behind the Indexes page tiles — tables read by full scan with no index, unused indexes and redundant indexes, from the sys schema views schema_tables_with_full_table_scans, schema_unused_indexes and schema_redundant_indexes — plus the number and total size of secondary indexes in user schemas (the primary key is not counted, matching the size) and the server's uptime in seconds, which is how long the since-start counts have been accumulating. The first two counts are since the server (or the performance_schema counters) last restarted, and are only reported while performance_schema table I/O instrumentation is on. A count is blank, with the reason in the matching Note column, whenever it could not be checked (the account cannot read the view, the sys schema is missing, performance_schema is off, or the statement timed out); it is never 0 for a check that did not run. Collected hourly. No alert is set on it.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `full_scan_tables` | Tables Read by Full Scan | NA |  |  |
| `unused_indexes` | Indexes Unused Since Restart | NA |  |  |
| `redundant_indexes` | Indexes Covered by Another Index | NA |  |  |
| `total_index_count` | Total Secondary Indexes | NA |  |  |
| `total_index_bytes` | Total Secondary Index Size | BYTE |  |  |
| `uptime_seconds` | Server Uptime | SECOND |  |  |
| `full_scan_note` | Full Scan Note | NA |  |  |
| `unused_note` | Unused Note | NA |  |  |
| `redundant_note` | Redundant Note | NA |  |  |
| `totals_note` | Totals Note | NA |  |  |

## MySQL InnoDB Cluster (`ip_mysql_cluster_beta`)

### Response (`Response`) — collected every 1 Min

Availability. EM derives the target's Up/Down state from the Status column; a Status below 1 raises the target-down event.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `Status` | Status (0/1: 1 = up, 0 = down) | NA |  | < 1 |

### Group Replication Members (`GroupMembers`) — collected every 5 Min

Group Replication membership — each member's host, port, role, state, and version, from performance_schema.replication_group_members.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `member_id` (key) | Member ID | NA |  |  |
| `channel_name` | Channel Name | NA |  |  |
| `member_host` | Member Host | NA |  |  |
| `member_port` | Member Port | NA |  |  |
| `member_state` | Member State (ONLINE\|RECOVERING\|OFFLINE\|ERROR\|UNREACHABLE) | NA |  |  |
| `member_role` | Member Role (PRIMARY \| SECONDARY) | NA |  |  |
| `member_version` | Member Version | NA |  |  |
| `is_online` | Member Online (0/1: 1 = ONLINE) | NA |  |  |
| `is_primary` | Member Is Primary (0/1: 1 = PRIMARY) | NA |  |  |

### Group Replication Member Stats (`GroupMemberStats`) — collected every 5 Min

Per-member Group Replication certification and applier queue statistics, from performance_schema.replication_group_member_stats.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `member_id` (key) | Member ID | NA |  |  |
| `channel_name` | Channel Name | NA |  |  |
| `view_id` | View ID | NA |  |  |
| `count_transactions_in_queue` | Transactions Queued for Certification (current) | NA | > 100 | > 1000 |
| `count_transactions_checked` | Transactions Checked (cumulative since member joined) | NA |  |  |
| `count_conflicts_detected` | Conflicts Detected (cumulative since member joined) | NA |  |  |
| `count_transactions_rows_validating` | Rows Held for Certification (current) | NA |  |  |
| `transactions_committed_all_members` | Transactions Committed All Members | NA |  |  |
| `last_conflict_free_transaction` | Last Conflict Free Transaction | NA |  |  |
| `count_transactions_remote_in_applier_queue` | Remote Transactions in Applier Queue (current) | NA | > 100 | > 1000 |
| `count_transactions_remote_applied` | Remote Transactions Applied (cumulative since member joined) | NA |  |  |
| `count_transactions_local_proposed` | Local Transactions Proposed (cumulative since member joined) | NA |  |  |
| `count_transactions_local_rollback` | Local Transactions Rolled Back (cumulative since member joined) | NA |  |  |

### Group Replication Summary (`GroupSummary`) — collected every 5 Min

Single-row rollup of Group Replication membership by state and role — online, recovering, unreachable, and offline member counts, and primary/secondary counts — derived from the group's membership view.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `member_count` | Members in Group (total) | NA |  |  |
| `online_count` | Members ONLINE | NA |  |  |
| `recovering_count` | Members RECOVERING | NA |  |  |
| `unreachable_count` | Members UNREACHABLE | NA |  |  |
| `error_count` | Members in ERROR State | NA |  |  |
| `offline_count` | Members OFFLINE | NA |  |  |
| `primary_count` | Members with PRIMARY Role | NA |  |  |
| `secondary_count` | Members with SECONDARY Role | NA |  |  |

### Group Replication Consensus (`GrConsensus`) — collected every 5 Min

Group Replication consensus activity for the connected member, as deltas over the collection interval — proposals, timing, and bytes sent/received — from the server's Gr_* status counters.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `member_id` (key) | Member ID | NA |  |  |
| `consensus_proposals` | Consensus Proposals (since prev. collection, ~5 min) | NA |  |  |
| `consensus_time_total_us` | Consensus Time Total (since prev. collection, ~5 min) | MICROSEC |  |  |
| `avg_consensus_time_us` | Avg Consensus Time per Proposal (since prev. collection, ~5 min) | MICROSEC | > 100000 | > 1000000 |
| `empty_consensus_proposals` | Empty Consensus Proposals (since prev. collection, ~5 min) | NA |  |  |
| `empty_proposal_pct` | Empty Proposals (% of proposals, since prev. collection) | PERCENTAGE |  |  |
| `extended_consensus_count` | Extended Consensus Rounds (since prev. collection, ~5 min) | NA |  |  |
| `extended_consensus_pct` | Extended Consensus (% of proposals, since prev. collection) | PERCENTAGE |  |  |
| `consensus_bytes_sent` | Consensus Bytes Sent (since prev. collection, ~5 min) | BYTE |  |  |
| `consensus_bytes_received` | Consensus Bytes Received (since prev. collection, ~5 min) | BYTE |  |  |
| `last_consensus_end` | Last Consensus End | NA |  |  |

### Group Replication Messaging (`GrMessaging`) — collected every 5 Min

Group Replication messaging activity for the connected member, as deltas over the collection interval — control and data messages sent, bytes transferred, and round-trip time — from the server's Gr_* status counters.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `member_id` (key) | Member ID | NA |  |  |
| `total_messages_sent` | Total Messages Sent (since prev. collection, ~5 min) | NA |  |  |
| `control_messages_sent` | Control Messages Sent (since prev. collection, ~5 min) | NA |  |  |
| `control_messages_bytes` | Control Message Bytes (since prev. collection, ~5 min) | BYTE |  |  |
| `control_roundtrip_time_us` | Control Roundtrip Time Total (since prev. collection, ~5 min) | MICROSEC |  |  |
| `avg_control_roundtrip_us` | Avg Control Roundtrip per Message (since prev. collection) | MICROSEC |  |  |
| `data_messages_sent` | Data Messages Sent (since prev. collection, ~5 min) | NA |  |  |
| `data_messages_bytes` | Data Message Bytes (since prev. collection, ~5 min) | BYTE |  |  |
| `data_roundtrip_time_us` | Data Roundtrip Time Total (since prev. collection, ~5 min) | MICROSEC |  |  |
| `avg_data_roundtrip_us` | Avg Data Roundtrip per Message (since prev. collection, ~5 min) | MICROSEC |  |  |

### Group Replication Certification (`GrCertification`) — collected every 5 Min

Group Replication certification and consistency-wait activity for the connected member, as deltas over the collection interval — garbage collection runs and consistency-check timings — from the server's Gr_* status counters.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `member_id` (key) | Member ID | NA |  |  |
| `certification_gc_runs` | Certification GC Runs (since prev. collection, ~5 min) | NA |  |  |
| `certification_gc_time_us` | Certification GC Time (since prev. collection, ~5 min) | MICROSEC |  |  |
| `consistency_before_begin_count` | Consistency Waits, Before Begin (since prev. collection, ~5 min) | NA |  |  |
| `consistency_before_begin_time_us` | Consistency Wait Time, Before Begin (since prev. collection) | MICROSEC |  |  |
| `consistency_after_sync_count` | Consistency Waits, After Sync (since prev. collection, ~5 min) | NA |  |  |
| `consistency_after_sync_time_us` | Consistency Wait Time, After Sync (since prev. collection) | MICROSEC |  |  |
| `consistency_after_termination_count` | Consistency Waits, After Termination (since prev. collection) | NA |  |  |
| `consistency_after_termination_time_us` | Consistency Wait, After Termination (since prev. collection) | MICROSEC |  |  |

### Backup Source (`BackupSource`) — collected every 15 Min

Which cluster member the most recent successful backup was taken from, and whether that member is still online in the group. Reads MySQL Enterprise Backup's mysql.backup_history joined against Group Replication membership; Percona XtraBackup backups are reported without member identity because PERCONA_SCHEMA.xtrabackup_history does not record it.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `source_uuid` | Source Member UUID | NA |  |  |
| `source_member` | Source Member | NA |  |  |
| `source_state` | Source Member State (ONLINE \| RECOVERING \| ... \| blank) | NA |  |  |
| `source_offline` | Backup Source Offline (0/1: 1 = offline; -1 = unknown) | NA | > 0 |  |
| `last_success_end_time` | Last Successful Backup End Time | NA |  |  |
| `tool` | Backup Tool | NA |  |  |

## MySQL InnoDB ClusterSet (`ip_mysql_clusterset_beta`)

### Response (`Response`) — collected every 1 Min

Availability. EM derives the target's Up/Down state from the Status column; a Status below 1 raises the target-down event.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `Status` | Status (up/down) | NA |  | < 1 |

### ClusterSet Health (`ClusterSetHealth`) — collected every 5 Min

Single-row alertable ClusterSet health composite. Runs mysqlsh AdminAPI (clusterSet.status) from the agent host; requires mysqlsh on the agent's PATH. dr_promotion_ready is 1 when the ClusterSet can be failed over, 0 when a readiness check ran and failed, and -1 when readiness was not assessed (the repository rollup, or MySQL Shell could not be used), with health_status READY, NOT_READY or UNKNOWN to match; under a network partition the Shell reports HEALTHY with the replication channel CONNECTING, which this metric surfaces as not promotion-ready.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `health_source` | Health Source (ADMINAPI \| REPOSITORY_ROLLUP \| UNAVAILABLE) | NA |  |  |
| `fallback_reason` | Fallback Reason (MYSQLSH_NOT_FOUND \| AUTH_FAILED \| ...) | NA | matches ^(AUTH_FAILED\|TIMEOUT\|UNREACHABLE\|MEMBER_UNREACHABLE\|KERBEROS_TICKET\|KERBEROS_CONFIG_UNREADABLE\|TLS_TRUSTSTORE_REQUIRED\|PARSE_FAILED)$ |  |
| `primary_healthy` | Primary Healthy (0/1: 1=yes, 0=no; -1=not assessed) | NA |  |  |
| `replica_clusters_healthy` | Replica Clusters Healthy (0/1: 1=yes, 0=no; -1=not assessed) | NA |  |  |
| `replication_channel_ok` | Replication Channel OK (0/1: 1=yes, 0=no; -1=not assessed) | NA |  |  |
| `gtid_lag` | GTID Lag (transactions behind; -1 not assessed) | NA |  |  |
| `errant_gtid_count` | Errant GTID Count (transactions; -1 not assessed) | NA |  |  |
| `dr_promotion_ready` | DR Promotion Ready (1 ready \| 0 check failed \| -1 not assessed) | NA |  | = 0 |
| `replica_cluster_count` | Replica Cluster Count (-1 not assessed) | NA |  |  |
| `domain_name` | Domain Name | NA |  |  |
| `primary_cluster` | Primary Cluster | NA |  |  |
| `global_primary_instance` | Global Primary Instance | NA |  |  |
| `status` | Status | NA |  |  |
| `status_text` | Status Text | NA |  |  |
| `health_status` | Health Status (READY \| NOT_READY \| UNKNOWN) | NA |  |  |

### ClusterSet Clusters (`ClusterSetClusters`) — collected every 5 Min

Per-cluster ClusterSet detail, keyed by cluster name — role, status, replication status, and GTID consistency versus the primary. Runs mysqlsh AdminAPI (clusterSet.status) from the agent host; requires mysqlsh on the agent's PATH.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `cluster_name` (key) | Cluster | NA |  |  |
| `cluster_role` | Role (PRIMARY \| REPLICA) | NA |  |  |
| `global_status` | Global Status (OK \| OK_NOT_REPLICATING = stopped \| NOT_OK \| ...) | NA |  |  |
| `cluster_set_replication_status` | ClusterSet Replication (OK \| STOPPED \| ...; blank on primary) | NA |  |  |
| `transaction_set_consistency_status` | Transaction Set Consistency (OK \| INCONSISTENT \| UNAVAILABLE) | NA |  |  |
| `missing_gtid_count` | Missing Transactions | NA |  |  |
| `errant_gtid_count` | Errant Transactions | NA |  |  |
| `primary_instance` | Primary Instance | NA |  |  |
| `missing_gtid_set` | Missing GTID Set | NA |  |  |
| `errant_gtid_set` | Errant GTID Set | NA |  |  |

### Monitoring Readiness Detail (`readiness_detail`) — collected on demand

Monitoring Readiness checks, one row per requirement, keyed by feature section and check — what each feature needs, what is in effect now, and a status of ok, warn, fail or unknown (unknown means the check could not be made, never a pass). It is probed live under the target's monitoring credentials each time the Monitoring Readiness page loads, not collected on a schedule, so nothing is stored and a change to the server shows on the next page load. Database targets are checked for the monitoring grants, performance_schema, the sys schema, a backup tool history and the plug-in licence; ClusterSet targets for the connection and for MySQL Shell on the agent host. A failed connection is a row, not an error. The page is read-only: the statement that would fix a check is in its Detail, and the plug-in never runs it.

| Column | Label | Unit | Warning | Critical |
|---|---|---|---|---|
| `section` (key) | Feature Section | NA |  |  |
| `item` (key) | Check Id | NA |  |  |
| `database_name` | Database Name (blank: one scope per target) | NA |  |  |
| `label` | Requirement | NA |  |  |
| `mandatory` | Mandatory (0/1: 1 = required, 0 = optional) | NA |  |  |
| `required` | Required Value | NA |  |  |
| `current` | Current Value | NA |  |  |
| `status` | Status (ok \| warn \| fail \| unknown) | NA |  |  |
| `fixable` | Fixable by the Plug-in (0/1: always 0 in this release) | NA |  |  |
| `detail` | Detail and Suggested Fix | NA |  |  |
