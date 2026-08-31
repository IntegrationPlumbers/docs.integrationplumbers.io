---
title: Target discovery
nav_order: 5.5
---

# MySQL Target Discovery

## Automatic discovery (self-managed, on-host MySQL)
Enterprise Manager auto-discovers MySQL instances running on a **monitored agent host**.
The agent detects the local `mysqld` process(es) and proposes one target per instance,
named **`<host>:<port>`** (stable across restarts — no PID in the name). Promote a
proposed target and supply credentials to begin monitoring.

Multiple instances on one host are each discovered by their listening port.

## RDS / Aurora / Cloud SQL / other managed MySQL — add manually
Managed-cloud MySQL has **no host process** the agent can see, so it **cannot be
auto-discovered**. Add these instances manually via **Add Target → Add Manually**,
supplying the endpoint host, port, and credentials. (Auto-discovery is local-host only
by design.)
