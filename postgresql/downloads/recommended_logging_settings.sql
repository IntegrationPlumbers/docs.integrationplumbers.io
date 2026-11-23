-- recommended_logging_settings.sql
-- OPTIONAL. The server logging settings that give the PostgreSQL plug-in's log-enhanced features the
-- most to work with. Review each line before running: every one changes what your server writes to its
-- log, and all of them are the DBA's call. Nothing here is required for the plug-in to run; without
-- them the pages explain what is missing instead of failing.
--
--   psql -h <host> -d postgres -U <superuser> -f recommended_logging_settings.sql
--
-- ALTER SYSTEM writes postgresql.auto.conf; pg_reload_conf() applies the reloadable ones. Settings that
-- need a restart (shared_preload_libraries) are listed at the end as comments. Needs psql 10 or later.
--
-- PATRONI-MANAGED CLUSTERS: Patroni owns postgresql.conf and overrides ALTER SYSTEM at the next restart.
-- Put the same values in the DCS instead, e.g.
--   patronictl -c /etc/patroni/patroni.yml edit-config -s postgresql.parameters.log_autovacuum_min_duration=0 --force
-- (one -s per setting; a value with % or a trailing space must be YAML-quoted:
--   -s 'postgresql.parameters.log_line_prefix="%m [%p] %q%u@%d %e "'), and let Patroni apply them to every member.

-- 1. Record every autovacuum run (vacuum history, dead-row and bloat findings). 0 = every run.
ALTER SYSTEM SET log_autovacuum_min_duration = 0;

-- 2. Name the user and database on every line and carry the SQLSTATE: events on the Logs page can
--    then be filtered by database and are routed by error code, not only by message text. Keep %m
--    and [%p]; %q stops the prefix for background processes. Change this only if nothing else parses
--    your log by its current prefix.
ALTER SYSTEM SET log_line_prefix = '%m [%p] %q%u@%d %e ';

-- 3. Keep server messages in English (the plug-in recognises English texts; the SQLSTATE in the
--    prefix above covers categorization in any language, but the vacuum history needs English).
ALTER SYSTEM SET lc_messages = 'C';

-- 4. More event categories on the Logs page. Pick thresholds that suit the server's volume.
ALTER SYSTEM SET log_min_duration_statement = '1s';   -- slow statements (set -1 to turn off)
ALTER SYSTEM SET log_temp_files = '10MB';              -- sorts / hashes spilling to disk
ALTER SYSTEM SET log_lock_waits = on;                  -- waits longer than deadlock_timeout
ALTER SYSTEM SET log_checkpoints = on;                 -- the default from PostgreSQL 15
-- ALTER SYSTEM SET log_connections = on;              -- connection churn; high volume on busy servers

-- 5. Match captured plans to statements (the setting exists from PostgreSQL 14).
SELECT current_setting('server_version_num')::int >= 140000 AS has_compute_query_id \gset
\if :has_compute_query_id
ALTER SYSTEM SET compute_query_id = on;
\endif

SELECT pg_reload_conf();

-- Needs a RESTART, so it is not run here. auto_explain is configured afterwards from the plug-in's
-- Monitoring Readiness page (its Configure action sets the auto_explain.* values), and
-- pg_stat_statements needs CREATE EXTENSION pg_stat_statements in each monitored database.
--   ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements, auto_explain';
-- Optional extensions that also need preloading before CREATE EXTENSION: pg_qualstats, pg_wait_sampling.
