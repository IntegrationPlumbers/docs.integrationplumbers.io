-- enable_log_enhanced_features.sql
-- Grants the PostgreSQL plug-in's monitoring role what the log-enhanced features need, in the database
-- you are connected to. Idempotent: safe to run again. Run as a superuser: it installs a superuser-owned
-- server-log reader (schema xpgs_monitor, three SECURITY DEFINER functions) and grants the role EXECUTE on
-- it, so the role can read the server log and nothing else on the host.
--
--   psql -h <host> -d <database> -U <dba> -v role=<monitoring role> -f enable_log_enhanced_features.sql
--   psql ... -v role=<monitoring role> -v dry_run=1 -f enable_log_enhanced_features.sql   (show, then roll back;
--                                                     dry_run=0 or leaving it out applies the grants)
--
-- Needs psql 11 or later (\if and :{?name}). Always write the variable as -v dry_run=1: a bare -v dry_run unsets it.
--
-- Functions and their grants are PER DATABASE: run this in every database the plug-in monitors (or use
-- enable_log_enhanced_features.sh, which loops over them). pg_monitor membership is cluster-wide and is
-- simply re-granted. The role is never given pg_read_server_files, and (now that the xpgs_monitor
-- reader exists) no longer needs EXECUTE on the built-in pg_current_logfile / pg_stat_file / pg_read_file,
-- which would let it read every file inside the data and log directories (pg_hba.conf, table files).
-- xpgs_monitor.current_log_file / log_file_size / log_read accept only a file that sits directly in the
-- server's log_directory (the current log and its rotated siblings) and run as their superuser owner.
-- A role that was granted the built-ins earlier keeps working: the plug-in prefers the xpgs_monitor
-- reader when it can execute it and falls back to the built-ins otherwise. This script revokes nothing.

\set QUIET on
\set ON_ERROR_STOP on
\if :{?role}
\else
\echo 'usage: psql -d <database> -v role=<monitoring role> [-v dry_run=1] -f enable_log_enhanced_features.sql'
\echo '       (psql 11 or later: an older psql cannot see -v role and always lands here; nothing was granted)'
\quit
\endif

BEGIN;
-- First statement, before any function call: this script runs as a superuser, and an unqualified call
-- would otherwise resolve through the session's search_path. A function planted in public (any role can
-- create one there on PostgreSQL 14 and earlier) such as pg_has_role(text, text, text) is a better match
-- for an untyped argument than the pg_catalog one and would run with the superuser's rights. The catalog
-- calls below are schema-qualified as well. SET LOCAL ends with the transaction.
SET LOCAL search_path = pg_catalog, pg_temp;
SET LOCAL client_min_messages = warning;   -- no "already a member" notice on a re-run

-- psql does not substitute variables inside a DO block, so the role travels in a transaction-local
-- setting. A missing role raises, which ON_ERROR_STOP turns into a non-zero exit (the wrapper counts it).
SELECT pg_catalog.set_config('onboarding.role', :'role', true) AS onboarding_role \gset
DO $enable$
DECLARE r text := pg_catalog.current_setting('onboarding.role');
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = r) THEN
    RAISE EXCEPTION 'role % does not exist; create it first (CREATE ROLE % LOGIN PASSWORD ''...'';)', r, pg_catalog.quote_ident(r);
  END IF;
END
$enable$;

-- Required by every page: the standard monitoring role (pg_stat_* views, pg_stat_statements, settings).
GRANT pg_monitor TO :"role";

-- Required by the log-based features in THIS database: the narrow server-log reader. Owned by the
-- superuser running this script (SECURITY DEFINER), search_path pinned, EXECUTE revoked from PUBLIC.
-- log_path validates the file name against log_directory (relative to the data directory or absolute,
-- as pg_current_logfile reports it): no '..', no other directory, no subdirectory.
-- A schema named xpgs_monitor that already exists and is not owned by a superuser was not installed by
-- this script: someone with CREATE on the database planted it, and CREATE OR REPLACE would keep that owner
-- (the plug-in refuses such a schema; see LogFileReader). Stop here so a DBA looks at it.
DO $guard$
DECLARE o text;
BEGIN
  SELECT r.rolname INTO o FROM pg_catalog.pg_namespace n JOIN pg_catalog.pg_roles r ON r.oid = n.nspowner
   WHERE n.nspname = 'xpgs_monitor' AND NOT r.rolsuper;
  IF o IS NOT NULL THEN
    RAISE EXCEPTION 'schema xpgs_monitor already exists and is owned by non-superuser %; drop it (DROP SCHEMA xpgs_monitor CASCADE) before installing the log reader', o;
  END IF;
END
$guard$;
CREATE SCHEMA IF NOT EXISTS xpgs_monitor;
ALTER SCHEMA xpgs_monitor OWNER TO CURRENT_USER;
REVOKE ALL ON SCHEMA xpgs_monitor FROM PUBLIC;
GRANT USAGE ON SCHEMA xpgs_monitor TO :"role";

CREATE OR REPLACE FUNCTION xpgs_monitor.log_path(fname text) RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $fn$
DECLARE
  datadir  text := current_setting('data_directory');
  logdir   text := current_setting('log_directory');
  resolved text;   -- (not "full": a reserved word)
BEGIN
  IF fname IS NULL OR fname = '' THEN
    RAISE EXCEPTION 'server log file name required';
  END IF;
  IF left(logdir, 1) <> '/' THEN
    logdir := datadir || '/' || logdir;
  END IF;
  resolved := CASE WHEN left(fname, 1) = '/' THEN fname ELSE datadir || '/' || fname END;
  -- plain string comparison, not LIKE: a directory name containing % or _ must not widen the match
  IF position('..' IN resolved) > 0
     OR left(resolved, length(logdir) + 1) <> logdir || '/'
     OR position('/' IN substr(resolved, length(logdir) + 2)) > 0 THEN
    RAISE EXCEPTION 'not a server log file: %', fname;
  END IF;
  RETURN fname;
END
$fn$;

CREATE OR REPLACE FUNCTION xpgs_monitor.current_log_file(fmt text DEFAULT NULL) RETURNS text
LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $fn$
  SELECT CASE WHEN fmt IS NULL THEN pg_current_logfile() ELSE pg_current_logfile(fmt) END
$fn$;

CREATE OR REPLACE FUNCTION xpgs_monitor.log_file_size(fname text) RETURNS bigint
LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $fn$
  SELECT size FROM pg_stat_file(xpgs_monitor.log_path(fname))
$fn$;

CREATE OR REPLACE FUNCTION xpgs_monitor.log_read(fname text, off bigint, len bigint) RETURNS text
LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog, pg_temp AS $fn$
  SELECT pg_read_file(xpgs_monitor.log_path(fname), off, len)
$fn$;

-- Ownership is asserted after every CREATE OR REPLACE (which keeps a pre-existing owner): the plug-in
-- only trusts superuser-owned SECURITY DEFINER functions here.
ALTER FUNCTION xpgs_monitor.log_path(text) OWNER TO CURRENT_USER;
ALTER FUNCTION xpgs_monitor.current_log_file(text) OWNER TO CURRENT_USER;
ALTER FUNCTION xpgs_monitor.log_file_size(text) OWNER TO CURRENT_USER;
ALTER FUNCTION xpgs_monitor.log_read(text, bigint, bigint) OWNER TO CURRENT_USER;
REVOKE ALL ON FUNCTION xpgs_monitor.log_path(text), xpgs_monitor.current_log_file(text),
  xpgs_monitor.log_file_size(text), xpgs_monitor.log_read(text, bigint, bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION
  xpgs_monitor.current_log_file(text),
  xpgs_monitor.log_file_size(text),
  xpgs_monitor.log_read(text, bigint, bigint)
TO :"role";

-- The previous model, kept for reference and still honoured by the plug-in when present: EXECUTE on the
-- built-ins pg_current_logfile(), pg_current_logfile(text), pg_stat_file(text) and
-- pg_read_file(text, bigint, bigint). Not granted here; it also lets the role read any file inside the
-- data and log directories.

\pset format aligned
\pset border 2
\pset title 'Grants for the log-enhanced features'
SELECT pg_catalog.current_database()                                                            AS database,
       :'role'                                                                       AS role,
       pg_catalog.pg_has_role(:'role', 'pg_monitor', 'MEMBER')                                  AS pg_monitor,
       pg_catalog.has_function_privilege(:'role', 'xpgs_monitor.current_log_file(text)', 'EXECUTE')
         AND pg_catalog.has_function_privilege(:'role', 'xpgs_monitor.log_file_size(text)', 'EXECUTE')
         AND pg_catalog.has_function_privilege(:'role', 'xpgs_monitor.log_read(text, bigint, bigint)', 'EXECUTE') AS xpgs_monitor_reader,
       pg_catalog.has_function_privilege(:'role', 'pg_current_logfile()', 'EXECUTE')
         AND pg_catalog.has_function_privilege(:'role', 'pg_current_logfile(text)', 'EXECUTE')
         AND pg_catalog.has_function_privilege(:'role', 'pg_stat_file(text)', 'EXECUTE')
         AND pg_catalog.has_function_privilege(:'role', 'pg_read_file(text, bigint, bigint)', 'EXECUTE') AS builtin_log_functions;
\pset title

-- Any value other than 0 / false / off / no (and an empty one) means dry run.
\if :{?dry_run}
\else
\set dry_run 0
\endif
SELECT COALESCE(NULLIF(pg_catalog.lower(:'dry_run'), ''), '1') NOT IN ('0', 'false', 'off', 'no') AS is_dry \gset
\if :is_dry
ROLLBACK;
\echo 'dry run: nothing was changed'
\else
COMMIT;
\endif
