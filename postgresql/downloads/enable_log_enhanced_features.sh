#!/usr/bin/env bash
# enable_log_enhanced_features.sh
# Runs enable_log_enhanced_features.sql in every database the PostgreSQL plug-in monitors (the log-read
# grants are per database), with one connection setting for all of them. Needs psql 11 or later and a DBA login.
#
#   ./enable_log_enhanced_features.sh --role <monitoring role> [--databases db1,db2] [--dry-run] [-- <psql options>]
#
#   --role        the plug-in's monitoring role (the one named in the target's credentials)
#   --databases   comma-separated list; default: every database that accepts connections, templates excluded
#   --dry-run     show what each database would get, then roll back
#   -- ...        anything after -- goes to psql (e.g. -- -h db.example.com -p 5432 -U postgres)
#
# Connection details can also come from the usual PG* environment variables and ~/.pgpass.
# Example:  PGPASSWORD=... ./enable_log_enhanced_features.sh --role oem_monitor -- -h 10.0.0.5 -U postgres
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sql="$here/enable_log_enhanced_features.sql"
role=""
databases=""
dry_run=""

usage() { sed -n '2,14p' "$0"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --role)      [ $# -ge 2 ] || { echo "--role needs a value" >&2; exit 2; }; role="$2"; shift 2 ;;
    --role=*)    role="${1#--role=}"; shift ;;
    --databases) [ $# -ge 2 ] || { echo "--databases needs a value" >&2; exit 2; }; databases="$2"; shift 2 ;;
    --databases=*) databases="${1#--databases=}"; shift ;;
    --dry-run)   dry_run="-v dry_run=1"; shift ;;
    --)          shift; break ;;
    --help)      usage; exit 0 ;;
    -h|-p|-U|-d) echo "psql options such as $1 go after -- (see --help)" >&2; exit 2 ;;
    *)           echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done
psql_opts=("$@")
# Note: "${psql_opts[@]}" on an empty array trips `set -u` on bash < 4.4 (macOS, RHEL 7), hence the
# ${psql_opts[@]+"${psql_opts[@]}"} form below.

if [ -z "$role" ]; then
  echo "--role <monitoring role> is required" >&2
  exit 2
fi
if [ ! -r "$sql" ]; then
  echo "cannot read $sql" >&2
  exit 2
fi
command -v psql >/dev/null || { echo "psql not found on PATH" >&2; exit 2; }
# The SQL script tests its variables with :{?name}, which psql 10 does not have: there it prints its usage
# line, grants nothing and still exits 0, which this wrapper would report as done.
psql_major="$(psql --version | sed -n 's/^[^0-9]*\([0-9][0-9]*\).*/\1/p')"
if [ -z "$psql_major" ] || [ "$psql_major" -lt 11 ]; then
  echo "psql 11 or later is required (found: $(psql --version))" >&2
  exit 2
fi

# Database names are catalog data, not trusted input: libpq treats a -d value containing '=' or
# starting with postgresql:// as a whole connection string (host included), so every name is passed
# as a quoted dbname='...' keyword. Inside those quotes only a single quote or a backslash could
# break out, and bash versions disagree on how to escape them (bash 3.2 turns \' into \\'), so names
# containing either, or a line break (which would split the list), are skipped with a warning
# instead of escaped. No monitored database needs such a name. Anyone with CREATEDB can choose one.
unsafe_name() { case "$1" in *\'*|*\\*|*$'\n'*|*$'\r'*) return 0 ;; esac; return 1; }
dbname_arg() { printf "dbname='%s'" "$1"; }

if [ -z "$databases" ]; then
  # One listing connection to the maintenance database (-d postgres unless the caller set PGDATABASE):
  # unsafe names come back as a control-character marker so they are counted, not connected to.
  # This runs as the DBA: the search_path is pinned in the same transaction as the query (one -c, so the
  # pin also holds, and ends, behind a transaction-pooling proxy; there is no COMMIT because psql before
  # 15 prints only the last statement's result, and the read-only transaction ends with the connection)
  # and every catalog name is
  # schema-qualified with exact argument types, so a function planted in public (strpos(name, text) would
  # beat the catalog's strpos(text, text) for the name column) is never picked up.
  listed="$(psql -X -q -At -v ON_ERROR_STOP=1 ${psql_opts[@]+"${psql_opts[@]}"} -d "$(dbname_arg "${PGDATABASE:-postgres}")" \
    -c "BEGIN READ ONLY; SET LOCAL search_path = pg_catalog, pg_temp; SELECT CASE WHEN pg_catalog.strpos(datname::pg_catalog.text, pg_catalog.chr(39)) > 0 OR pg_catalog.strpos(datname::pg_catalog.text, pg_catalog.chr(92)) > 0 OR pg_catalog.strpos(datname::pg_catalog.text, pg_catalog.chr(10)) > 0 OR pg_catalog.strpos(datname::pg_catalog.text, pg_catalog.chr(13)) > 0 THEN pg_catalog.chr(1) ELSE datname::pg_catalog.text END FROM pg_catalog.pg_database WHERE datallowconn AND NOT datistemplate ORDER BY datname")"
  skipped=0
  databases=""
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    if [ "$name" = $'\x01' ]; then skipped=$((skipped + 1)); continue; fi
    databases="${databases:+$databases$'\n'}$name"
  done <<< "$listed"
  [ "$skipped" != "0" ] && echo "warning: $skipped database(s) whose name contains a quote, a backslash or a line break were skipped" >&2
  separator=$'\n'
else
  separator=','
fi
if [ -z "$databases" ]; then
  echo "no databases found" >&2
  exit 1
fi

status=0
while IFS= read -r db; do
  [ -z "$db" ] && continue
  if unsafe_name "$db"; then
    echo "== skipping a database name containing a quote or backslash: $db" >&2
    status=1
    continue
  fi
  echo "== $db"
  # shellcheck disable=SC2086  # dry_run is intentionally two words or empty
  if ! psql -X ${psql_opts[@]+"${psql_opts[@]}"} -d "$(dbname_arg "$db")" -v role="$role" $dry_run -f "$sql"; then
    echo "   failed in $db (see the error above); continuing with the next database" >&2
    status=1
  fi
done <<< "${databases//$separator/$'\n'}"

if [ $status -eq 0 ]; then
  echo "done${dry_run:+ (dry run, nothing changed)}: role $role in: ${databases//$'\n'/, }"
else
  echo "finished with errors; re-run after fixing them (the script is safe to repeat)" >&2
fi
exit $status
