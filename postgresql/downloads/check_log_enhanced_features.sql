-- check_log_enhanced_features.sql
-- Read-only report of every prerequisite the PostgreSQL plug-in's log-enhanced features need, for the
-- database you are connected to and the monitoring role you name. Nothing is changed.
--
--   psql -h <host> -d <database> -U <dba> -v role=<monitoring role> -f check_log_enhanced_features.sql
--
-- Run it once per monitored database (the log-read grants are per database). Without -v role the
-- connected user is checked. The same checks appear on the plug-in's Monitoring Readiness page once a
-- target is monitored; this script lets you prepare a server before adding it.
--
-- Status values: OK = in place, ACTION = needed for a log-enhanced feature, OPTIONAL = enables more
-- (extensions, extra event categories). Needs psql 10 or later (\if).

\set QUIET on
\if :{?role}
\else
\set role ''
\endif
\pset format aligned
\pset border 2
\pset title 'Log-enhanced features readiness'

WITH r AS (
  SELECT COALESCE(NULLIF(:'role', ''), current_user::text) AS role_name
), s AS (
  SELECT
    current_database()                                              AS db,
    current_setting('server_version_num')::int                      AS vnum,
    current_setting('logging_collector', true)                      AS logging_collector,
    current_setting('log_destination', true)                        AS log_destination,
    current_setting('lc_messages', true)                            AS lc_messages,
    current_setting('log_line_prefix', true)                        AS log_line_prefix,
    current_setting('log_autovacuum_min_duration', true)            AS log_autovacuum_min_duration,
    current_setting('log_min_duration_statement', true)             AS log_min_duration_statement,
    current_setting('log_temp_files', true)                         AS log_temp_files,
    current_setting('log_lock_waits', true)                         AS log_lock_waits,
    current_setting('log_connections', true)                        AS log_connections,
    current_setting('log_checkpoints', true)                        AS log_checkpoints,
    current_setting('shared_preload_libraries', true)               AS shared_preload_libraries,
    current_setting('compute_query_id', true)                       AS compute_query_id,
    current_setting('auto_explain.log_min_duration', true)          AS ae_min_duration,
    current_setting('auto_explain.log_format', true)                AS ae_format,
    current_setting('auto_explain.log_analyze', true)               AS ae_analyze,
    current_setting('auto_explain.log_verbose', true)               AS ae_verbose
), fn AS (
  SELECT array_agg(f ORDER BY f) FILTER (WHERE NOT has_function_privilege(r.role_name, f, 'EXECUTE')) AS missing
  FROM r, unnest(ARRAY['pg_current_logfile()', 'pg_current_logfile(text)', 'pg_stat_file(text)',
                       'pg_read_file(text, bigint, bigint)']) AS f
  WHERE EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name)
), nfn AS (
  -- the narrow xpgs_monitor reader: present, trusted (SECURITY DEFINER, superuser-owned, schema
  -- usable by the role: a schema merely named xpgs_monitor is ignored by the plug-in) and executable. The
  -- CASE guards keep has_function_privilege away from a missing function (it would raise), since PostgreSQL
  -- does not promise AND short-circuit order.
  SELECT bool_and(to_regprocedure(f) IS NOT NULL) AS installed,
         bool_and(CASE WHEN to_regprocedure(f) IS NOT NULL THEN
                    EXISTS (SELECT 1 FROM pg_proc p JOIN pg_roles o ON o.oid = p.proowner
                             WHERE p.oid = to_regprocedure(f) AND p.prosecdef AND o.rolsuper)
                    AND has_schema_privilege(r.role_name, 'xpgs_monitor', 'USAGE')
                  ELSE false END) AS trusted,
         bool_and(CASE WHEN to_regprocedure(f) IS NOT NULL THEN has_function_privilege(r.role_name, f, 'EXECUTE') ELSE false END) AS executable
  FROM r, unnest(ARRAY['xpgs_monitor.current_log_file(text)', 'xpgs_monitor.log_file_size(text)',
                       'xpgs_monitor.log_read(text, bigint, bigint)']) AS f
  WHERE EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name)
), ext AS (
  SELECT e.name,
         (SELECT extversion FROM pg_extension x WHERE x.extname = e.name) AS installed,
         a.default_version AS available
  FROM unnest(ARRAY['pg_stat_statements', 'pgstattuple', 'pg_qualstats', 'hypopg', 'pg_wait_sampling']) AS e(name)
  LEFT JOIN pg_available_extensions a ON a.name = e.name
), checks AS (
  -- 1. the monitoring role
  SELECT 10.0 AS n, 'Monitoring role exists' AS item,
         CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name) THEN 'OK' ELSE 'ACTION' END AS status,
         r.role_name AS current, 'CREATE ROLE ' || quote_ident(r.role_name) || ' LOGIN PASSWORD ''...'';' AS recommended
  FROM r
  UNION ALL
  SELECT 10.5, 'Monitoring role can log in',
         CASE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name) THEN 'ACTION'
              WHEN (SELECT rolcanlogin FROM pg_roles WHERE rolname = r.role_name) THEN 'OK' ELSE 'ACTION' END,
         CASE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name) THEN 'role missing'
              WHEN (SELECT rolcanlogin FROM pg_roles WHERE rolname = r.role_name) THEN 'LOGIN' ELSE 'NOLOGIN' END,
         'ALTER ROLE ' || quote_ident(r.role_name) || ' LOGIN;'
  FROM r
  UNION ALL
  SELECT 11, 'Role is a member of pg_monitor (required)',
         CASE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name) THEN 'ACTION'
              WHEN pg_has_role(r.role_name, 'pg_monitor', 'MEMBER') THEN 'OK' ELSE 'ACTION' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name)
              THEN CASE WHEN pg_has_role(r.role_name, 'pg_monitor', 'MEMBER') THEN 'member' ELSE 'not a member' END
              ELSE 'role missing' END,
         'GRANT pg_monitor TO ' || quote_ident(r.role_name) || ';'
  FROM r
  UNION ALL
  SELECT 12, 'Role can read the server log in database ' || s.db || ' (required for log-based features)',
         CASE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name) THEN 'ACTION'
              WHEN COALESCE(nfn.trusted, false) AND COALESCE(nfn.executable, false) THEN 'OK'
              WHEN fn.missing IS NULL THEN 'OK' ELSE 'ACTION' END,
         CASE WHEN NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name) THEN 'role missing'
              WHEN COALESCE(nfn.trusted, false) AND COALESCE(nfn.executable, false) THEN 'xpgs_monitor log reader installed and granted (reads the server log only)'
              WHEN COALESCE(nfn.installed, false) AND NOT COALESCE(nfn.trusted, false) THEN 'a schema named xpgs_monitor exists but is NOT the plug-in''s reader (not superuser-owned SECURITY DEFINER functions, or no USAGE for the role): the plug-in ignores it'
                || CASE WHEN fn.missing IS NULL THEN '; the built-ins are granted and in use' ELSE '; built-ins missing: ' || array_to_string(fn.missing, ', ') END
              WHEN fn.missing IS NULL THEN 'EXECUTE granted on the four built-in functions (the role can read any file in the data and log directories; the xpgs_monitor reader is narrower)'
              WHEN COALESCE(nfn.installed, false) THEN 'xpgs_monitor log reader installed but not granted to the role; built-ins missing: ' || array_to_string(fn.missing, ', ')
              ELSE 'missing: ' || array_to_string(fn.missing, ', ') END,
         'run enable_log_enhanced_features.sql as a superuser in THIS database (installs the xpgs_monitor log reader and grants it to '
           || quote_ident(r.role_name) || '); the older alternative is GRANT EXECUTE ON FUNCTION pg_current_logfile(), '
           || 'pg_current_logfile(text), pg_stat_file(text), pg_read_file(text, bigint, bigint) TO ' || quote_ident(r.role_name) || ';'
  FROM r, s, fn, nfn
  UNION ALL
  -- 2. the server log itself
  SELECT 20, 'Server writes a log file the plug-in can read',
         CASE WHEN s.logging_collector = 'on' AND s.log_destination ~ 'stderr' THEN 'OK'
              WHEN s.logging_collector = 'on' AND s.vnum >= 150000 AND s.log_destination ~ 'jsonlog' THEN 'OK'
              ELSE 'ACTION' END,
         'logging_collector = ' || s.logging_collector || ', log_destination = ' || s.log_destination
           || ' (PostgreSQL ' || (s.vnum / 10000) || ')'
           || CASE WHEN s.logging_collector = 'on' AND s.log_destination !~ 'stderr' AND s.vnum >= 150000 AND s.log_destination ~ 'jsonlog'
                   THEN ': jsonlog feeds the vacuum history and the Logs page events; plan capture needs stderr' ELSE '' END,
         'logging_collector = on and stderr or jsonlog (PostgreSQL 15 and later) in log_destination: the vacuum history '
           || 'and the Logs page events read either; plan capture reads stderr only; csvlog is not read'
  FROM s
  UNION ALL
  SELECT 21, 'Server messages are in English',
         CASE WHEN s.lc_messages IS NULL OR s.lc_messages = '' OR lower(s.lc_messages) IN ('c', 'posix')
                   OR lower(s.lc_messages) LIKE 'c.%' OR lower(s.lc_messages) LIKE 'en%' THEN 'OK' ELSE 'ACTION' END,
         'lc_messages = ' || COALESCE(s.lc_messages, '(default)'),
         'lc_messages = C or an en_* locale (the plug-in recognises English messages)'
  FROM s
  UNION ALL
  SELECT 22, 'Autovacuum runs are logged (vacuum history, bloat findings)',
         CASE WHEN s.log_autovacuum_min_duration = '0' THEN 'OK'
              WHEN s.log_autovacuum_min_duration = '-1' THEN 'ACTION' ELSE 'OPTIONAL' END,
         'log_autovacuum_min_duration = ' || s.log_autovacuum_min_duration,
         '0 records every run; -1 records none; a duration records only runs longer than it'
  FROM s
  UNION ALL
  SELECT 23, 'Log line prefix names the user and database',
         CASE WHEN s.log_line_prefix LIKE '%\%u%' AND s.log_line_prefix LIKE '%\%d%' THEN 'OK' ELSE 'OPTIONAL' END,
         'log_line_prefix = ''' || s.log_line_prefix || '''',
         'include %u@%d (events can then be filtered by database) and %e (the SQLSTATE routes events exactly), '
           || 'e.g. ''%m [%p] %q%u@%d %e '''
  FROM s
  UNION ALL
  SELECT 24, 'Log line prefix carries the SQLSTATE',
         CASE WHEN s.log_line_prefix LIKE '%\%e%' THEN 'OK' ELSE 'OPTIONAL' END,
         CASE WHEN s.log_line_prefix LIKE '%\%e%' THEN '%e present' ELSE '%e absent' END,
         'add %e to log_line_prefix'
  FROM s
  UNION ALL
  -- 3. plan capture (auto_explain) and statement statistics
  SELECT 30, 'pg_stat_statements loaded and installed here (statement monitoring, Workload History)',
         CASE WHEN s.shared_preload_libraries ~ 'pg_stat_statements' AND e.installed IS NOT NULL THEN 'OK' ELSE 'ACTION' END,
         'shared_preload_libraries ' || CASE WHEN s.shared_preload_libraries ~ 'pg_stat_statements' THEN 'has it' ELSE 'lacks it' END
           || '; extension ' || COALESCE('installed ' || e.installed, CASE WHEN e.available IS NULL THEN 'not available on this server' ELSE 'available ' || e.available || ', not installed here' END),
         'shared_preload_libraries = ''pg_stat_statements'' (restart) and CREATE EXTENSION pg_stat_statements;'
  FROM s, ext e WHERE e.name = 'pg_stat_statements'
  UNION ALL
  SELECT 31, 'auto_explain loaded (log-based plan capture)',
         CASE WHEN s.shared_preload_libraries ~ 'auto_explain' THEN 'OK' ELSE 'OPTIONAL' END,
         'shared_preload_libraries = ''' || COALESCE(s.shared_preload_libraries, '') || '''',
         'add auto_explain to shared_preload_libraries (restart); then configure it from the Monitoring Readiness page'
  FROM s
  UNION ALL
  SELECT 32, 'auto_explain settings (plan capture needs log_min_duration >= 0, log_format = json, log_analyze = on)',
         CASE WHEN s.shared_preload_libraries !~ 'auto_explain' THEN 'OPTIONAL'
              WHEN s.ae_min_duration IS NOT NULL AND s.ae_min_duration <> '-1' AND s.ae_format = 'json' AND s.ae_analyze = 'on' THEN 'OK'
              ELSE 'OPTIONAL' END,
         'log_min_duration = ' || COALESCE(s.ae_min_duration, '(unset)') || ', log_format = ' || COALESCE(s.ae_format, '(unset)')
           || ', log_analyze = ' || COALESCE(s.ae_analyze, '(unset)') || ', log_verbose = ' || COALESCE(s.ae_verbose, '(unset)'),
         'the plug-in''s Configure action on the Monitoring Readiness page sets these (log_verbose = on adds the query id)'
  FROM s
  UNION ALL
  SELECT 33, 'compute_query_id (matches captured plans to statements)',
         CASE WHEN s.compute_query_id IN ('on', 'auto') THEN 'OK' ELSE 'OPTIONAL' END,
         'compute_query_id = ' || COALESCE(s.compute_query_id, '(unset)'),
         'compute_query_id = on (or auto with pg_stat_statements loaded)'
  FROM s
  UNION ALL
  -- 4. optional extensions
  SELECT 40 + row_number() OVER (ORDER BY e.name), 'Optional extension ' || e.name || ' (' ||
           CASE e.name WHEN 'pgstattuple' THEN 'measured table bloat on the Vacuum Advisor'
                       WHEN 'pg_qualstats' THEN 'predicate-based index recommendations'
                       WHEN 'hypopg' THEN 'what-if index simulations'
                       WHEN 'pg_wait_sampling' THEN 'wait-event history' END || ')',
         CASE WHEN e.installed IS NOT NULL THEN 'OK' ELSE 'OPTIONAL' END,
         COALESCE('installed ' || e.installed, CASE WHEN e.available IS NULL THEN 'not available on this server' ELSE 'available ' || e.available || ', not installed here' END),
         CASE WHEN e.installed IS NOT NULL THEN 'nothing to do'
              WHEN e.available IS NULL THEN 'install the extension package on the server, then CREATE EXTENSION ' || e.name || ';'
              ELSE 'CREATE EXTENSION ' || e.name || ';' || CASE WHEN e.name IN ('pg_qualstats', 'pg_wait_sampling') THEN ' (also needs shared_preload_libraries + restart)' ELSE '' END END
  FROM ext e WHERE e.name <> 'pg_stat_statements'
  UNION ALL
  -- 5. optional logging that feeds more event categories on the Logs page
  SELECT 50, 'Slow statements logged (log_min_duration_statement)',
         CASE WHEN s.log_min_duration_statement <> '-1' THEN 'OK' ELSE 'OPTIONAL' END,
         'log_min_duration_statement = ' || s.log_min_duration_statement,
         'e.g. 1s: statements slower than this appear as slow-statement events'
  FROM s
  UNION ALL
  SELECT 51, 'Temporary files logged (log_temp_files)',
         CASE WHEN s.log_temp_files <> '-1' THEN 'OK' ELSE 'OPTIONAL' END,
         'log_temp_files = ' || s.log_temp_files,
         'e.g. 10MB: sorts and hashes spilling to disk appear as temporary-file events'
  FROM s
  UNION ALL
  SELECT 52, 'Lock waits logged (log_lock_waits)',
         CASE WHEN s.log_lock_waits = 'on' THEN 'OK' ELSE 'OPTIONAL' END,
         'log_lock_waits = ' || s.log_lock_waits,
         'on: waits longer than deadlock_timeout appear as lock-wait events'
  FROM s
  UNION ALL
  SELECT 53, 'Connections logged (log_connections)',
         CASE WHEN s.log_connections = 'on' THEN 'OK' ELSE 'OPTIONAL' END,
         'log_connections = ' || s.log_connections,
         'on: connection churn appears as an event category (high volume on busy servers)'
  FROM s
  UNION ALL
  SELECT 54, 'Checkpoints logged (log_checkpoints)',
         CASE WHEN s.log_checkpoints = 'on' THEN 'OK' ELSE 'OPTIONAL' END,
         'log_checkpoints = ' || s.log_checkpoints,
         'on (the default since PostgreSQL 15): checkpoints and too-frequent-checkpoint warnings appear as events'
  FROM s
)
SELECT status, item, current, recommended
FROM checks
ORDER BY n;

\pset title
\echo
\echo 'ACTION rows block a log-enhanced feature; OPTIONAL rows enable more. The grants are per database:'
\echo 'run this script, or enable_log_enhanced_features.sh, in every database the plug-in monitors.'
