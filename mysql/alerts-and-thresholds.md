---
title: Alerts and thresholds
nav_order: 8
---

# Alert thresholds

This chapter lists the default thresholds the plug-in ships and how to change them.
**Topics:** 7.1 Default thresholds · 7.2 Changing thresholds
## 7.1 Default thresholds
The plug-in ships 19 default metric thresholds, listed below, plus 3 availability conditions (the `Status` column of each target type's Response metric, which drive the target's Up/Down state and are not shown here).

| Target type | Metric group | Column | Operator | Warning | Critical | Consecutive occurrences |
|---|---|---|---|---|---|---|
| `ip_mysql_database_beta` | ReplicationReplicaActivity | `seconds_behind_source` | > | 30 | 300 | 1 |
| `ip_mysql_database_beta` | ReplicationReplicaActivity | `replica_io_running` | = | — | No | 1 |
| `ip_mysql_database_beta` | ReplicationReplicaActivity | `replica_sql_running` | = | — | false | 1 |
| `ip_mysql_database_beta` | InnodbBufferPool | `innodb_bp_hit_rate` | < | 95 | 90 | 1 |
| `ip_mysql_database_beta` | InnodbTransaction | `innodb_trx_history_list_length` | > | 100000 | 1000000 | 1 |
| `ip_mysql_database_beta` | ConnectionActivity | `aborted_connects_delta` | > | 10 | 50 | 1 |
| `ip_mysql_database_beta` | ThreadsActivity | `connection_saturation_pct` | > | 80 | 95 | 1 |
| `ip_mysql_database_beta` | TableActivity | `disk_tmp_table_pct` | > | 25 | 50 | 1 |
| `ip_mysql_database_beta` | SysSchemaStatus | `sys_supported` | < | — | 1 | 1 |
| `ip_mysql_database_beta` | BackupStatus | `hours_since_last_success` | > | 26 | 50 | 1 |
| `ip_mysql_database_beta` | BackupStatus | `last_backup_failed` | > | — | 0 | 1 |
| `ip_mysql_database_beta` | BackupStatus | `never_succeeded` | > | — | 0 | 1 |
| `ip_mysql_database_beta` | License | `licensed` | < | — | 1 | 1 |
| `ip_mysql_database_beta` | License | `days_remaining` | < | 30 | 7 | 1 |
| `ip_mysql_cluster_beta` | GroupMemberStats | `count_transactions_remote_in_applier_queue` | > | 100 | 1000 | 1 |
| `ip_mysql_cluster_beta` | GroupMemberStats | `count_transactions_in_queue` | > | 100 | 1000 | 1 |
| `ip_mysql_cluster_beta` | GrConsensus | `avg_consensus_time_us` | > | 100000 | 1000000 | 1 |
| `ip_mysql_cluster_beta` | BackupSource | `source_offline` | > | 0 | — | 1 |
| `ip_mysql_clusterset_beta` | ClusterSetHealth | `dr_promotion_ready` | < | — | 1 | 2 |

## 7.2 Changing thresholds
The shipped values are starting points sized for lab workloads, not tuning. Review each one against your own service levels and change the ones that do not fit.

Thresholds live on the target, and you edit them from Metric and Collection Settings:

1. From the target's home page, choose the target-type menu → **Monitoring → Metric and Collection Settings**.
2. Set the **View** list to **All metrics** so that columns without a current threshold are listed too.
3. Find the metric group and column — 7.1 gives both names for every shipped threshold, and the metrics reference ([6.1](metrics-reference.md#where-the-reference-is)) gives them for every other column.
4. Edit **Warning Threshold** and **Critical Threshold** on the row, or click the row's edit icon for the full editor.
5. Set **Number of Occurrences** if the condition should have to hold for more than one collection before it raises an incident. The shipped thresholds use one occurrence, except `dr_promotion_ready`, which uses two.
6. Click **OK** to save. The new value applies from the next collection.

Clearing a threshold field removes the threshold: the column keeps collecting and stops alerting. The same page changes a group's collection schedule, and can stop a group collecting altogether — use that rather than deleting a target when you want to quiet a metric group.

Confirm what a target is actually carrying:

```
emcli get_threshold -target_name="mysql84-prod-01" -target_type="ip_mysql_database_beta"
```

> **Note:** A threshold edited this way is an override on that one target, and applying a monitoring template to the target replaces it with the template's value. Where a value should hold across a fleet, put it in a monitoring template — **Enterprise → Monitoring → Monitoring Templates**, created from a MySQL target and applied to a group — rather than editing targets one at a time and having the next template apply undo the work.
