---
title: Targets and properties
nav_order: 5
---

# Adding and modifying targets

This chapter describes adding MySQL database, cluster and ClusterSet targets from the console and with EM CLI, autodiscovery, modifying and removing targets, and associating compliance standards.
**Topics:** 4.1 Target properties · 4.2 Add a target manually · 4.3 Add a target with EM CLI · 4.4 Autodiscovery · 4.5 Modify or remove a target · 4.6 Associate compliance standards
## 4.1 Target properties
Every MySQL target is defined by the same small set of monitoring properties, whichever way you add it. The names in bold are the labels on the console page; the names in parentheses are the property keys EM CLI takes ([4.3](#add-a-target-with-em-cli)).

**User** and **Password** are credential properties. In the console they appear in the credentials area of the Add Target page; with EM CLI they go in `-credentials` rather than in `-properties`.

**MySQL Database (`ip_mysql_database`)**

- **User** (`ip_mysql_database_username`): the monitoring account from [2.4](prerequisites.md#the-monitoring-user), user name only, without the host part.
- **Password** (`ip_mysql_database_password`): that account's password.
- **Host (default - localhost)** (`ip_mysql_database_host`): host name or IP address of the MySQL server as the agent host reaches it. Leave it empty only for a socket connection ([2.6](prerequisites.md#unix-socket-connections)).
- **Port (default - 3306)** (`ip_mysql_database_port`): the server's listening port.
- **Unix Socket Path (socket connections)** (`ip_mysql_database_socket`): full path to the server's socket file. Local agent only — leave Host empty when you set it.
- **TLS Mode (disabled / required / verify_ca / verify_identity)** (`ip_mysql_database_use_secure`): transport security for this target. See 2.5.
- **Kerberos Configuration File** (`ip_mysql_database_kerberos_config`): full path to a `krb5.conf` on the agent host, for Kerberos authentication.
- **License Key** (`ip_mysql_database_license`): the signed licence key issued for this plug-in, pasted as one line. The console lets you add the target without it, but nothing except availability collects until the key is accepted: the `License` metric reports the reason (`License Required` for no key) and raises a CRITICAL incident, **and every other metric group on the target reports a collection error — `Collection stopped by license status: …` — until the status is `Active`**; availability keeps reporting, so the target stays Up rather than Down. Cluster and ClusterSet targets are containers, not licensed targets, and are never stopped. The key is checked entirely on the agent host — nothing is sent to the MySQL server or outside Enterprise Manager — every 15 minutes, and again as soon as the property changes. The `Status` column of the `License` metric gives the reason a key is not accepted: `Invalid Signature` (the key was altered), `Wrong Plug-in` (a key issued for the other edition of this plug-in), or `Expired`.

**MySQL Cluster (`ip_mysql_cluster`)**

The same properties, with the `ip_mysql_cluster_` prefix in place of `ip_mysql_database_`, and two labels that read differently:

- **(Router) Host** (`ip_mysql_cluster_host`) and **(Router) Port** (`ip_mysql_cluster_port`): point these at a MySQL Router endpoint, or directly at any member of the cluster. The target reads cluster-wide state through whichever member it lands on.
- **User** / **Password** (`ip_mysql_cluster_username`, `ip_mysql_cluster_password`): the monitoring account must carry the grants in [2.4](prerequisites.md#the-monitoring-user) on the cluster. Created on the primary, it replicates to every member.
- **TLS Mode**, **Unix Socket Path** and **Kerberos Configuration File** behave exactly as they do for a MySQL Database target.

**MySQL ClusterSet (`ip_mysql_clusterset`)**

The same properties again with the `ip_mysql_clusterset_` prefix, plus one that only this type has:

- **(Router) Host** / **(Router) Port** (`ip_mysql_clusterset_host`, `ip_mysql_clusterset_port`): the Router endpoint, or a member, that the JDBC collections use.
- **DR Max Tolerated GTID Lag (transactions)** (`ip_mysql_clusterset_dr_max_lag`): how many transactions the replica cluster may be behind the primary cluster and still count as ready for promotion. The `dr_promotion_ready` condition ([7.1](alerts-and-thresholds.md#default-thresholds)) evaluates against it.

> **Note:** A ClusterSet target also needs `mysqlsh` on its agent host ([2.2](prerequisites.md#mysql-shell-for-clusterset-targets)), and in this release its TLS Mode should be `required` or `disabled` ([2.5](prerequisites.md#tls)).

## 4.2 Add a target manually
![Add Target Manually — declarative property form for a MySQL Database target](images/add-target.png)
Use this route for a single target, and for any endpoint autodiscovery cannot see ([4.4](#autodiscovery)).

1. Make sure the plug-in is deployed to the agent that will monitor the target ([3.3](install-and-upgrade.md#deploy-to-agents)). Until it is, the MySQL target types are not offered for that agent.
2. In the console, choose **Setup → Add Target → Add Targets Manually**.
3. Select **Add Targets Declaratively by Specifying Target Monitoring Properties**.
4. In **Target Type**, select **MySQL Database**.
5. In **Monitoring Agent**, select the agent that will run the collections — this is the agent host, not the MySQL server — then click **Add Manually**.
6. Enter a **Target Name**. This is the display name used throughout the console and the name EM CLI verbs take. `<host>:<port>` is the convention autodiscovery uses and it stays readable at scale.
7. Fill in the monitoring properties from [4.1](#target-properties). At minimum supply **User**, **Password**, **Host**, **Port** and the **License Key**, plus **TLS Mode** if the server requires an encrypted session. A target added without a key comes Up but collects nothing except availability until a key is accepted ([4.1](#target-properties)).
8. Click **Test Connection**. A failure here is a credential, network or TLS problem; fix it before you continue, because a target added with wrong properties is added Down.
9. Click **OK** to create the target.

Repeat for **MySQL Cluster** and **MySQL ClusterSet**, choosing that target type in step 4 and filling in the properties listed for it in [4.1](#target-properties).

The target appears in the console within a couple of minutes, and its metric groups populate on their own schedules.

> **Note:** Cluster and ClusterSet targets are independent of the MySQL Database targets for the same servers. You can add either without the other, and adding a cluster target does not create database targets for its members.

## 4.3 Add a target with EM CLI
EM CLI creates the same target as the console and is the practical route once you are onboarding more than a handful of servers.

`add_target` takes the display name, the target type, the **agent** host, and the monitoring properties split across two options:

| Console target type | `-type` value | Property prefix |
|---|---|---|
| MySQL Database | `ip_mysql_database` | `ip_mysql_database_` |
| MySQL Cluster | `ip_mysql_cluster` | `ip_mysql_cluster_` |
| MySQL ClusterSet | `ip_mysql_clusterset` | `ip_mysql_clusterset_` |

| Console field | Key (`<prefix>` from the table above) | Option |
|---|---|---|
| User | `<prefix>username` | `-credentials` |
| Password | `<prefix>password` | `-credentials` |
| Host / (Router) Host | `<prefix>host` | `-properties` |
| Port / (Router) Port | `<prefix>port` | `-properties` |
| Unix Socket Path | `<prefix>socket` | `-properties` |
| TLS Mode | `<prefix>use_secure` | `-properties` |
| Kerberos Configuration File | `<prefix>kerberos_config` | `-properties` |
| License Key (MySQL Database only) | `ip_mysql_database_license` | `-properties` |
| DR Max Tolerated GTID Lag (ClusterSet only) | `ip_mysql_clusterset_dr_max_lag` | `-properties` |

Both options take `key:value` pairs separated by `;`. Log in first with `emcli login -username=<em user>`.

A MySQL Database target:

```
emcli add_target -name="mysql84-prod-01" -type="ip_mysql_database" \
  -host="agent-host.example.com" \
  -properties="ip_mysql_database_host:10.0.0.21;ip_mysql_database_port:3306;ip_mysql_database_use_secure:required;ip_mysql_database_license:<licence key>" \
  -credentials="ip_mysql_database_username:em_monitoring;ip_mysql_database_password:<password>"
```

A MySQL Cluster target, pointed at a Router endpoint:

```
emcli add_target -name="mysql84-prod-cluster" -type="ip_mysql_cluster" \
  -host="agent-host.example.com" \
  -properties="ip_mysql_cluster_host:10.0.0.30;ip_mysql_cluster_port:6446;ip_mysql_cluster_use_secure:required" \
  -credentials="ip_mysql_cluster_username:em_monitoring;ip_mysql_cluster_password:<password>"
```

A MySQL ClusterSet target, which adds the DR lag tolerance:

```
emcli add_target -name="mysql84-prod-clusterset" -type="ip_mysql_clusterset" \
  -host="agent-host.example.com" \
  -properties="ip_mysql_clusterset_host:10.0.0.30;ip_mysql_clusterset_port:6446;ip_mysql_clusterset_use_secure:required;ip_mysql_clusterset_dr_max_lag:100" \
  -credentials="ip_mysql_clusterset_username:em_monitoring;ip_mysql_clusterset_password:<password>"
```

Confirm the target was created:

```
emcli get_targets -targets="mysql84-prod-01:ip_mysql_database"
```

> **Note:** `-host` names the **agent** host that will monitor the target. The MySQL endpoint goes in the `<prefix>host` property, and the two are usually different — the same agent host appears in every command when one agent monitors many servers.

> **Note:** If a value has to contain `;` or `:`, override the separators rather than escaping them. Run `emcli help add_target` for the `-separator` and `-subseparator` syntax.

## 4.4 Autodiscovery
Enterprise Manager can propose MySQL Database targets for you on hosts it already monitors.

The plug-in's agent-side discovery detects every listening `mysqld` process on a monitored agent host and proposes one target per instance, named `<host>:<port>`. The name carries no process ID, so it is stable across restarts, and several instances on one host are proposed separately by their listening ports.

Agent-side discovery has to be enabled for the host before anything appears: under **Setup → Add Target → Configure Auto Discovery**, enable the MySQL discovery module on each host you want scanned and set its schedule.

To adopt a proposed target:

1. Choose **Setup → Add Target → Auto Discovery Results**.
2. Select the proposed MySQL Database target and click **Promote**.
3. Supply the monitoring credentials ([2.4](prerequisites.md#the-monitoring-user)) and the remaining properties from [4.1](#target-properties). **TLS Mode** in particular cannot be discovered — set it explicitly ([2.5](prerequisites.md#tls)).
4. Click **Promote** to finish. The target comes Up; it starts collecting once its **License Key** property is set (discovery does not supply one — open the target, *Target Setup → Monitoring Configuration*, and paste the key; see [4.1](#target-properties)).

> **Note:** Managed-cloud MySQL — Amazon RDS and Aurora, Google Cloud SQL, Azure Database for MySQL and their equivalents — has no host process for an agent to see, so it is never autodiscovered. Add those endpoints manually ([4.2](#add-a-target-manually) or 4.3), using the service endpoint as Host and its port.

MySQL Cluster and MySQL ClusterSet targets are not autodiscovered either. They are added against an endpoint you choose, so create them manually.

## 4.5 Modify or remove a target
Monitoring properties can be changed at any time; the change applies from the next collection.

To change a target's properties in the console:

1. From the target's home page, choose the target-type menu → **Target Setup → Monitoring Configuration**.
2. Edit the properties ([4.1](#target-properties)) and click **OK**.

Editing credentials, host, port or TLS Mode is the normal way to move a target to a new endpoint or to turn encryption on. You do not need to remove and re-add the target for any of them.

To remove a target, choose the target-type menu → **Target Setup → Remove Target** and confirm.

The EM CLI equivalents:

```
emcli modify_target -name="mysql84-prod-01" -type="ip_mysql_database" \
  -properties="ip_mysql_database_port:3307" -on_agent
```

```
emcli delete_target -name="mysql84-prod-01" -type="ip_mysql_database"
```

`-on_agent` pushes the change to the agent immediately instead of waiting for the next agent resynchronization.

> **Note:** Removing a target removes its collected metric history and its compliance associations with it. A target re-added under the same name starts both over, so prefer editing a target's properties to deleting and recreating it.

## 4.6 Associate compliance standards
Adding a target does not associate compliance standards with it — neither the console wizard nor emcli add_target carries an association, so a new target has no compliance evaluations until you associate the standards.

The plug-in ships five standards for `ip_mysql_database` targets, collected in one framework:

| Standard | Internal name |
|---|---|
| MySQL Administration Standard | `xmys_administration_standard` |
| MySQL Performance Standard | `xmys_performance_standard` |
| MySQL Replication Standard | `xmys_replication_standard` |
| MySQL Schema Standard | `xmys_schema_standard` |
| MySQL Security Standard | `xmys_security_standard` |

All five are authored by `INTEGRATION_PLUMBERS` at version 1. Chapter 9 describes the framework and every rule in it.

From the console:

1. Choose **Enterprise → Compliance → Library**.
2. On the **Compliance Frameworks** tab, select **MySQL Framework (Integration Plumbers)**. To associate a single standard instead, switch to the **Compliance Standards** tab and select one of the five.
3. Click **Associate Targets**.
4. Add the MySQL Database targets you want evaluated, then click **OK** and confirm.

With EM CLI, associate one standard at a time:

```
emcli associate_cs_targets -name="xmys_security_standard" -version=1 \
      -author=INTEGRATION_PLUMBERS -target_list="mysql84-prod-01"
```

Repeat the command for each of the five internal names you want evaluated on that target.

> **Note:** The two options take different name forms. `-name` takes the standard's *internal* name from the table above; `-target_list` takes the target *display name* alone.

Results appear on the target's compliance pages once a configuration collection has run against the newly associated standards. See 9.2 for reading them.
