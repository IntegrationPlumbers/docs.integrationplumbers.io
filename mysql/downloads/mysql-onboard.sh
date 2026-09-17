#!/usr/bin/env bash
# mysql-onboard.sh — bulk onboarding and omys/beta -> ip.em.xmys migration for
# the Integration Plumbers EM MySQL plug-in. Wraps standard emcli; needs an
# existing `emcli login` session. Documentation: the migration chapter and
# user guide 4.7 at https://docs.integrationplumbers.io/mysql/.
set -euo pipefail

VERSION="1.0.0"
EMCLI="${EMCLI:-emcli}"
HEADER='source_type,source_name,new_name,target_type,agent_host,host,port,socket,use_secure,kerberos_config,license_key,username,password,ts_dir,ts_type,notes'
NCOLS=16
# column indexes into F[] (csv_split output)
C_SRC_TYPE=0 C_SRC_NAME=1 C_NEW_NAME=2 C_TYPE=3 C_AGENT=4 C_HOST=5 C_PORT=6 C_SOCKET=7 C_SECURE=8 C_KRB=9 C_LIC=10 C_USER=11 C_PW=12 C_TSDIR=13 C_TSTYPE=14 C_NOTES=15
STANDARDS=(xmys_administration_standard xmys_performance_standard xmys_replication_standard xmys_schema_standard xmys_security_standard)
# The two truststore-backed modes are NOT in
# this release. opar/resources/target/ip_mysql_*.xml keep the truststore
# CredentialType/CredentialSet and the ts_* InstanceProperties inside
# <!-- DEFERRED --> blocks, and guide 2.5/4.1 say so; a tool that accepted them
# would build an add_target the OMS cannot honour. Reserved, not forgotten:
# the CSV keeps its use_secure vocabulary of four and its ts_dir/ts_type
# columns, and row_validate rejects the deferred half by name.
USE_SECURE_VALUES=' disabled required '
USE_SECURE_DEFERRED=' verify_ca verify_identity '
DEFERRED_MSG='not available in this release — see guide 4.1 (truststore credentials are deferred)'

MODE=""; CSV=""; OUT=""; SOURCE="all"; FORCE=0; DRY_RUN=0; YES=0; TIMEOUT=1200
AGENT_OVERRIDE=""; LOG=""; PW_ENV="MYSQL_MON_PW"; TSPW_ENV="MYSQL_TS_PW"; USERNAME_DEFAULT=""
MON_PW=""; TS_PW=""; EMCLI_OUT=""; ROW_PW=""
n_created=0; n_skipped=0; n_updated=0; n_warned=0; n_failed=0
# CWE-214: real emcli's
# add_target/modify_target -input_file option substitutes a file's contents
# for a tag inside -credentials, so the monitoring password never has to
# appear in argv (confirmed against emcli's own help output). -properties
# has no equivalent option, so the licence key still sits on the command
# line — see apply_row / build_props. CRED_TMPDIR is created once by
# mode_apply (ensure_cred_tmpdir, guarded against a second call) before the
# row loop starts and removed by the EXIT trap as a safety net; each row
# also removes its own file as soon as its emcli call returns — except under
# --dry-run, which never writes the file (or the password) to disk at all.
CRED_TMPDIR=""; CRED_PW_TAG='MYSQL_ONBOARD_PW'

# --- functions ---
usage() {
  cat <<'U'
mysql-onboard.sh <mode> [options]        (version 1.0.0)

Modes (run in this order for a migration: export, apply, verify, associate, retire):
  export     read omys / beta targets from EM into a CSV     --out FILE [--source omys|beta|all] [--force]
  apply      create the ip.em.xmys targets from the CSV       --csv FILE [--password-env VAR] [--ts-password-env VAR] [--username USER] [--agent HOST] [--dry-run]
  verify     wait for Up + License Active, print a table      --csv FILE [--timeout SECONDS]
  associate  associate the five shipped compliance standards  --csv FILE [--dry-run]
  retire     delete the source targets listed in the CSV      --csv FILE [--yes]
Common: --log FILE   --emcli PATH   -h | --help
Requires an emcli session: run `emcli login -username=<em user>` first.

--timeout is per target, not for the run (default 1200 seconds). A database
target is PASS only once its License metric says Active, and License collects
every 15 minutes, so a freshly created target can take up to 15 minutes to turn
Active even when everything is right. N targets that never come Up therefore
cost up to N x timeout in total; verify one row with --timeout 1 first if you
only want the table.

The run log (--log, default ./mysql-onboard-<mode>-<time>.log) and export's
--out file are created owner-only (mode 600): both can hold licence keys.

--ts-password-env and the CSV's ts_dir / ts_type columns are reserved, not
live: the client truststore credential set is deferred in this release, so a
non-empty value in any of them is refused, as are use_secure=verify_ca and
use_secure=verify_identity (guide 2.5, 4.1). use_secure takes disabled or
required.
U
}
# %s, not %b: a die message must print exactly what it was given. %b expanded
# backslash escapes in interpolated values (a Windows path, an emcli reply) as
# well as in the two multi-line messages that wanted them — those now carry
# real newlines instead.
die() { printf 'ERROR: %s\n' "$*" >&2; exit 2; }
log() { local line; line="$(date -u '+%Y-%m-%dT%H:%M:%SZ') $*"; echo "$line"; [ -n "$LOG" ] && printf '%s\n' "$line" >> "$LOG"; return 0; }
# redact <text> [extra secret…]: masks the run-time passwords, any per-row
# secrets, and the signature of every licence key in the text.
# A licence key is a secret the way a password
# is — it is what proves entitlement — and apply logs the whole -properties
# string, so every run log held its customers' keys in full. Only the signature
# is masked: the rest of the key (customer, type, expiration, instances) is
# what makes a log worth reading, and the CSV keeps the real key because the
# operator has to be able to re-apply from it.
redact() {
  local s="$1"; shift; local x
  for x in "$MON_PW" "$TS_PW" "$@"; do [ -n "$x" ] && s="${s//"$x"/<redacted>}"; done
  while [[ "$s" =~ signature=([0-9a-fA-F]+) ]]; do s="${s//signature=${BASH_REMATCH[1]}/signature=<redacted>}"; done
  printf '%s' "$s"
}
# csv_split <line>: RFC 4180 subset (quoted fields may hold commas and doubled quotes; no embedded newlines) -> F[]
csv_split() {
  local line="$1" i=0 ch field="" inq=0 n
  n=${#line}
  F=()
  while [ "$i" -lt "$n" ]; do
    ch="${line:i:1}"
    if [ "$inq" = 1 ]; then
      if [ "$ch" = '"' ]; then
        if [ "${line:i+1:1}" = '"' ]; then field+='"'; i=$((i+1)); else inq=0; fi
      else field+="$ch"; fi
    else
      case "$ch" in
        '"') inq=1 ;;
        ',') F+=("$field"); field="" ;;
        *)   field+="$ch" ;;
      esac
    fi
    i=$((i+1))
  done
  F+=("$field")
}
csv_quote() { local v="$1"; if [[ "$v" == *[,\"]* ]]; then v="${v//\"/\"\"}"; printf '"%s"' "$v"; else printf '%s' "$v"; fi; }
# csv_join <field…>: one CSV line
csv_join() { local out="" v first=1; for v in "$@"; do if [ "$first" = 1 ]; then first=0; else out+=","; fi; out+="$(csv_quote "$v")"; done; printf '%s\n' "$out"; }
# run_emcli <label> <args…>: logs the (redacted) command and (redacted) output, runs it unless --dry-run, captures EMCLI_OUT (unredacted, for callers to parse), returns emcli's rc
run_emcli() {
  local label="$1"; shift
  local shown="$EMCLI $*"; shown=$(redact "$shown" "$ROW_PW")
  if [ "$DRY_RUN" = 1 ]; then log "DRY-RUN $label: $shown"; EMCLI_OUT=""; return 0; fi
  log "RUN $label: $shown"
  local rc=0; set +e; EMCLI_OUT=$("$EMCLI" "$@" 2>&1); rc=$?; set -e
  [ -n "$LOG" ] && printf '%s\n' "$(redact "$EMCLI_OUT" "$ROW_PW")" | sed 's/^/    /' >> "$LOG"
  return $rc
}
# run_emcli_ro: read-only call that must run even under --dry-run
run_emcli_ro() { local d="$DRY_RUN"; DRY_RUN=0; local rc=0; run_emcli "$@" || rc=$?; DRY_RUN="$d"; return $rc; }
require_session() { run_emcli_ro sync sync || die "no emcli session (emcli sync failed): run 'emcli login -username=<em user>' first"; }
# validate_csv <file>: header and field count; dies with every problem listed
validate_csv() {
  local file="$1" lineno=0 line errs=""
  [ -r "$file" ] || die "cannot read $file"
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"  # a CRLF-terminated CSV (Excel, or any csv.writer's default dialect) must not fail the header check on an invisible trailing \r
    lineno=$((lineno+1))
    [[ "$line" == \#* ]] && continue
    if [ "$lineno" = 1 ] || [ -z "${_hdr_seen:-}" ]; then
      _hdr_seen=1
      [ "$line" = "$HEADER" ] || die "$file: header must be exactly:"$'\n'"  $HEADER"$'\n'"found:"$'\n'"  $line"
      continue
    fi
    [ -z "$line" ] && continue
    csv_split "$line"
    [ "${#F[@]}" = "$NCOLS" ] || errs+="  line $lineno: ${#F[@]} fields, expected $NCOLS"$'\n'
  done < "$file"
  [ -z "$errs" ] || die "$file has malformed rows:"$'\n'"$errs"
}
# for_each_row <file> <callback>: calls <callback> with F[] and ROW_LINE set for every data row
for_each_row() {
  local file="$1" cb="$2" line lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"  # same CRLF tolerance as validate_csv
    lineno=$((lineno+1)); [[ "$line" == \#* || -z "$line" || "$line" == "$HEADER" ]] && continue
    csv_split "$line"; ROW_LINE=$lineno; "$cb"
  done < "$file"
}
# exit_failed: the exit code is the number of failed rows, capped at 255. A
# process exit status is a single byte, so an uncapped 256 failed rows would
# exit 0 — a total failure indistinguishable from a clean run by any wrapper
# script. (2 is also the usage/validation exit code, where no row ran at all;
# the summary line is what tells the two apart.)
exit_failed() { exit $(( n_failed > 255 ? 255 : n_failed )); }
summary() {
  log "SUMMARY $MODE: created=$n_created skipped=$n_skipped updated=$n_updated warned=$n_warned failed=$n_failed"
  exit_failed
}
target_type_for() { case "$1" in
  oracle_omys_database|ip_mysql_database_beta)     echo ip_mysql_database;;
  oracle_omys_cluster|ip_mysql_cluster_beta)       echo ip_mysql_cluster;;
  oracle_omys_clusterset|ip_mysql_clusterset_beta) echo ip_mysql_clusterset;;
  *) return 1;; esac; }
strip_prefix() { local k="$1" p; for p in oracle_omys_database_ oracle_omys_cluster_ oracle_omys_clusterset_ ip_mysql_database_ ip_mysql_cluster_ ip_mysql_clusterset_; do k="${k#"$p"}"; done; printf '%s' "$k"; }
flag_add() { if [ -z "$NOTES" ]; then NOTES="$1"; else NOTES+="; $1"; fi; }
mode_export() {
  [ -f "$OUT" ] && [ "$FORCE" != 1 ] && die "$OUT exists; use --force to overwrite"
  local patterns=() p
  case "$SOURCE" in omys) patterns=("oracle_omys_%");; beta) patterns=("ip_mysql_%_beta");; all) patterns=("oracle_omys_%" "ip_mysql_%_beta");; *) die "--source must be omys, beta or all";; esac
  declare -A PROPS=() OS=() STATUS=()
  local targets="" line
  # agent OS map: agent target name is host:port
  # Two separate -search options, not one "A AND B" string: on real 24ai emcli
  # (confirmed on EM 24ai) a
  # single -search combining TARGET_TYPE and PROPERTY_NAME with AND silently
  # returns zero rows — no error — even though both conditions individually
  # match. Repeating -search= ANDs the conditions the way the single-string
  # form was meant to; either -search alone returns rows for other target
  # types / other properties, so the AND is load-bearing, not decorative.
  run_emcli_ro emd list -resource=TargetProperties -search="TARGET_TYPE='oracle_emd'" -search="PROPERTY_NAME='orcl_gtp_os'" -columns="TARGET_NAME,PROPERTY_VALUE" -format="name:csv" || die "cannot read agent list"
  # The empty-line guard its two sibling loops
  # below already had. An OMS whose agents carry no orcl_gtp_os property (or
  # any reply that is header-only) makes $EMCLI_OUT empty, <<< still feeds one
  # empty line, and csv_split's single empty field trips ${F[1]} under set -u —
  # export died on an estate it could otherwise have exported in full.
  while IFS= read -r line; do [ -z "$line" ] || [ "$line" = "TARGET_NAME,PROPERTY_VALUE" ] && continue; csv_split "$line"; OS["${F[0]%%:*}"]="${F[1]}"; done <<<"$EMCLI_OUT"
  # An empty map is not fatal: every other column still exports. Say so, once,
  # so the operator knows the AGENT flag could not be evaluated on any row
  # rather than reading its absence as "no Windows agents".
  [ "${#OS[@]}" -gt 0 ] || log "WARN agent OS map is empty — AGENT flags cannot be evaluated"
  for p in "${patterns[@]}"; do
    run_emcli_ro targets list -resource=Targets -search="TARGET_TYPE LIKE '$p'" -columns="TARGET_NAME,TARGET_TYPE,EMD_URL" -format="name:csv" || die "cannot list targets for $p"
    targets+="$(printf '%s\n' "$EMCLI_OUT" | grep -v '^TARGET_NAME,' || true)"$'\n'
    run_emcli_ro props list -resource=TargetProperties -search="TARGET_TYPE LIKE '$p'" -columns="TARGET_NAME,TARGET_TYPE,PROPERTY_NAME,PROPERTY_VALUE" -format="name:csv" || die "cannot list properties for $p"
    while IFS= read -r line; do [ -z "$line" ] || [ "$line" = "TARGET_NAME,TARGET_TYPE,PROPERTY_NAME,PROPERTY_VALUE" ] && continue; csv_split "$line"; PROPS["${F[0]}|${F[1]}|$(strip_prefix "${F[2]}")"]="${F[3]}"; done <<<"$EMCLI_OUT"
    run_emcli_ro status get_targets -targets="%:$p" -format="name:csv" || die "cannot read target status for $p"
    while IFS= read -r line; do [ -z "$line" ] || [ "$line" = "Status ID,Status,Target Type,Target Name" ] && continue; csv_split "$line"; STATUS["${F[3]}|${F[2]}"]="${F[1]}"; done <<<"$EMCLI_OUT"
  done
  # The CSV carries every exported licence key (and is where the operator
  # types passwords next), so create it owner-only before anything is written
  # into it — a chmod afterwards would leave a window at the default umask.
  # Created here, not on entry, so a failed read above leaves no stub behind.
  ( umask 077; : > "$OUT" ) || die "cannot write $OUT"
  { printf '# exported %s from %s by mysql-onboard.sh %s — review the notes column, then apply\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$(hostname)" "$VERSION"; printf '%s\n' "$HEADER"; } > "$OUT"
  local n=0 name type gtype agent NOTES tls_deferred
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    csv_split "$line"; name="${F[0]}"; type="${F[1]}"; agent="${F[2]#https://}"; agent="${agent#http://}"; agent="${agent%%:*}"
    gtype=$(target_type_for "$type") || { log "SKIP $name: unknown source type $type"; continue; }
    NOTES=""
    p() { printf '%s' "${PROPS["$name|$type|$1"]:-}"; }
    [ -n "$(p kerberos_kdc)$(p kerberos_realm)" ] && flag_add "KERBEROS: source sets kerberos_kdc/kerberos_realm; xmys reads krb5.conf only — set kerberos_config"
    if [ "$gtype" = ip_mysql_database ]; then
      if [ -n "$(p license)" ]; then flag_add "LICENSE: beta key exported; GA key required"; else flag_add "LICENSE: no key on source"; fi
    fi
    # dr_max_lag has no CSV column — it is a
    # GA-only ClusterSet property with no omys counterpart, and adding a
    # sixteenth-and-a-half column for one type is worse than a note. Carrying
    # it as an informational flag at least stops a silent loss: without this
    # the DR promotion-readiness threshold the operator tuned on the source
    # reverts to the shipped default on the new target with nothing said.
    # Informational, so apply does not treat it as unresolved (see row_validate).
    [ "$gtype" = ip_mysql_clusterset ] && [ -n "$(p dr_max_lag)" ] && flag_add "DRLAG: source sets dr_max_lag=$(p dr_max_lag); re-set it on the new target after apply (guide 4.5)"
    # The source's TLS surface may be
    # one the shipped plug-in defers. apply rejects those values anyway,
    # but only at apply time and one row at a time — flagging them at export
    # puts the decision in the review pass with every other one, and the flag
    # is refused as unresolved until the operator has actually made it. The
    # exported values are left as they are: the operator needs to see what the
    # source did before deciding what to put in their place.
    tls_deferred=""
    [[ "$USE_SECURE_DEFERRED" == *" $(p use_secure) "* ]] && tls_deferred="$(p use_secure)/truststore"
    [ -z "$tls_deferred" ] && [ -n "$(p ts_dir)$(p ts_type)" ] && tls_deferred="a client truststore"
    [ -n "$tls_deferred" ] && flag_add "TLS: source uses $tls_deferred; not available in this release — set use_secure to required or disabled and clear ts_dir/ts_type (guide 4.1)"
    [ "${OS[$agent]:-}" = Windows ] && flag_add "AGENT: Windows agent — not supported by ip.em.xmys; set agent_host to a Linux agent; if the target already exists, delete it first"
    [ "${STATUS["$name|$type"]:-Up}" != Up ] && flag_add "STATUS: source target is ${STATUS["$name|$type"]}"
    [[ "$name" =~ ^[A-Za-z0-9\ ._()-]+$ ]] || flag_add "NAME: display name has characters outside [A-Za-z0-9 ._()-]"
    csv_join "$type" "$name" "$name" "$gtype" "$agent" "$(p host)" "$(p port)" "$(p socket)" "$(p use_secure)" "$(p kerberos_config)" "$(p license)" "" "" "$(p ts_dir)" "$(p ts_type)" "$NOTES" >> "$OUT"
    n=$((n+1))
  done <<<"$targets"
  log "export: $n rows written to $OUT"
}
# check_no_emcli_separators <label> <value>: dies — WITHOUT ever echoing
# <value> — if it holds any of the four characters -properties/-credentials
# treat as delimiters. Covers inputs row_validate's per-row F[@] loops can
# never see: --username (USERNAME_DEFAULT) and the monitoring password
# (MON_PW) are not CSV cells (found because
# --username silently bypassed the per-row check, and the run-time passwords
# were checked for ';'/':' only, not '~'/'||'). The truststore password is no
# longer among them — it is refused outright, the credential set being deferred.
check_no_emcli_separators() {
  local label="$1" v="$2"
  [[ "$v" == *';'* || "$v" == *':'* || "$v" == *'~'* || "$v" == *'||'* ]] && die "$label: emcli credential values cannot contain ';' or ':'; use a different monitoring password or account"
  return 0
}
load_passwords() {
  MON_PW="${!PW_ENV:-}"
  if [ -z "$MON_PW" ]; then
    if [ -t 0 ]; then read -r -s -p "Monitoring password (used for rows with an empty password cell): " MON_PW; echo; else die "no monitoring password: set $PW_ENV (or --password-env VAR), or run interactively"; fi
  fi
  # The truststore credential set is deferred in the shipped plug-in, so
  # there is nothing for a truststore password to key. Refuse it here rather
  # than carry it silently into a -credentials string the OMS will not accept.
  TS_PW="${!TSPW_ENV:-}"
  [ -z "$TS_PW" ] || die "\$$TSPW_ENV: truststore passwords are $DEFERRED_MSG"
  # add_target/modify_target's -credentials option has no -separator override
  # on real emcli (confirmed on EM 24ai: "-separator=credentials" is
  # rejected outright, and
  # -separator=properties does not extend to -credentials) — it always uses
  # the default ";"/":" delimiters, so either of these two run-time inputs
  # holding a separator character would corrupt every row's -credentials
  # string the same way an unresolved CSV cell would.
  check_no_emcli_separators "\$$PW_ENV" "$MON_PW"
  check_no_emcli_separators "--username" "$USERNAME_DEFAULT"
  return 0
}
# csv_has_secret_cells <file>: true if any row carries a password or a licence
# key, naming the kinds it found in SECRET_KINDS. The licence key was once not
# treated as a secret, so an inventory holding nothing but keys — the normal
# shape of an export from beta, and of any greenfield CSV — passed the
# permission check at mode 644.
csv_has_secret_cells() {
  SECRET_KINDS=""
  _chk() {
    [ -n "${F[$C_PW]}" ] && [[ "$SECRET_KINDS" != *password* ]] && SECRET_KINDS+="${SECRET_KINDS:+ and }password"
    [ -n "${F[$C_LIC]}" ] && [[ "$SECRET_KINDS" != *license_key* ]] && SECRET_KINDS+="${SECRET_KINDS:+ and }license_key"
    return 0   # a row with neither must not end the scan (for_each_row propagates the callback's status)
  }
  for_each_row "$1" _chk
  [ -n "$SECRET_KINDS" ]
}
check_csv_perms() { if csv_has_secret_cells "$1"; then local m; m=$(stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"); [ "${m: -2}" = "00" ] || die "$1 holds $SECRET_KINDS cells but is readable by group/other (mode $m): run chmod 600 $1"; fi; }
# row_validate: appends problems to VALIDATION_ERRS (one per line) for the current F[]
row_validate() {
  local where="line $ROW_LINE (${F[$C_NEW_NAME]:-?})" v
  [ -n "${F[$C_NEW_NAME]}" ] || VALIDATION_ERRS+="  $where: new_name is empty"$'\n'
  case "${F[$C_TYPE]}" in ip_mysql_database|ip_mysql_cluster|ip_mysql_clusterset) ;; *) VALIDATION_ERRS+="  $where: target_type '${F[$C_TYPE]}' is not ip_mysql_database/cluster/clusterset"$'\n';; esac
  [ -n "${F[$C_AGENT]}$AGENT_OVERRIDE" ] || VALIDATION_ERRS+="  $where: agent_host is empty (or pass --agent)"$'\n'
  v="${F[$C_SECURE]}"
  if [[ "$USE_SECURE_DEFERRED" == *" $v "* ]]; then VALIDATION_ERRS+="  $where: use_secure '$v' is $DEFERRED_MSG"$'\n'
  else [ -z "$v" ] || [[ "$USE_SECURE_VALUES" == *" $v "* ]] || VALIDATION_ERRS+="  $where: use_secure '$v' must be one of${USE_SECURE_VALUES% }"$'\n'; fi
  # The ts_* columns are reserved for the release that ships the
  # truststore credential set. A value in one today would be dropped in
  # silence by build_creds, so say so instead.
  [ -n "${F[$C_TSDIR]}${F[$C_TSTYPE]}" ] && VALIDATION_ERRS+="  $where: ts_dir/ts_type are $DEFERRED_MSG"$'\n'
  [ -n "${F[$C_SOCKET]}" ] && [ -n "${F[$C_HOST]}" ] && VALIDATION_ERRS+="  $where: socket is set, so host must be empty"$'\n'
  [ -n "${F[$C_SOCKET]}${F[$C_HOST]}" ] || VALIDATION_ERRS+="  $where: host (or socket) is required"$'\n'
  for v in KERBEROS: LICENSE: AGENT: TLS:; do [[ "${F[$C_NOTES]}" == *"$v"* ]] && VALIDATION_ERRS+="  $where: unresolved $v flag in notes — fix the row and delete the flag"$'\n'; done
  [ -n "${F[$C_USER]}$USERNAME_DEFAULT" ] || VALIDATION_ERRS+="  $where: username is empty (or pass --username)"$'\n'
  # a licence key is an ip_mysql_database property (build_props emits it for
  # that type alone), so a key on a cluster/ClusterSet row is a mistake worth
  # naming rather than a cell to drop in silence
  [ "${F[$C_TYPE]}" != ip_mysql_database ] && [ -n "${F[$C_LIC]}" ] && VALIDATION_ERRS+="  $where: licence keys apply to database targets only"$'\n'
  # ... and a database row with no key is legal but nearly always an
  # oversight: the target is created and then collects nothing but License and
  # Response. A warning, not a refusal — a licence can be set later.
  [ "${F[$C_TYPE]}" = ip_mysql_database ] && [ -z "${F[$C_LIC]}" ] && log "WARN $where: no licence key — only License/Response will collect until one is set"
  for v in "${F[@]}"; do [[ "$v" == *'~'* || "$v" == *'||'* ]] && { VALIDATION_ERRS+="  $where: a value contains '~' or '||', the emcli separators"$'\n'; break; }; done
  # -credentials always uses emcli's default ";"/":" delimiters (see
  # load_passwords for why); username/password/ts_dir/ts_type feed that
  # string, so any of the four holding ';' or ':' would corrupt it the same
  # way a '~' or '||' would corrupt -properties.
  for v in "${F[$C_USER]}" "${F[$C_PW]}" "${F[$C_TSDIR]}" "${F[$C_TSTYPE]}"; do [[ "$v" == *';'* || "$v" == *':'* ]] && { VALIDATION_ERRS+="  $where: username/password/ts_dir/ts_type contains ';' or ':' — -credentials has no separator override on real emcli"$'\n'; break; }; done
  return 0
}
# build_props / build_creds read F[] -> PROPS_STR / CREDS_STR (k~v||k~v); ROW_PW holds the secret used
build_props() {
  local p="${F[$C_TYPE]}_" out=""
  add() { [ -n "$2" ] && out+="${out:+||}$p$1~$2"; return 0; }
  add host "${F[$C_HOST]}"; add port "${F[$C_PORT]}"; add socket "${F[$C_SOCKET]}"; add use_secure "${F[$C_SECURE]}"; add kerberos_config "${F[$C_KRB]}"
  [ "${F[$C_TYPE]}" = ip_mysql_database ] && add license "${F[$C_LIC]}"
  PROPS_STR="$out"
}
build_creds() {
  # ";"/":" — not "||"/"~" — deliberately: add_target/modify_target's
  # -credentials has no -separator override on real emcli (see
  # load_passwords / row_validate), so it always takes the tool's default
  # delimiters; row_validate refuses any of these four fields holding
  # either character before we ever get here.
  # No ts_dir/ts_type/ts_pass. The credential set they belong to is
  # deferred in the shipped plug-in, row_validate refuses the cells, and
  # emitting them here would key credentials the OMS has no table for.
  # CWE-214: the password itself does NOT go into CREDS_STR —
  # $CRED_PW_TAG stands in for it, and apply_row resolves the tag through
  # -input_file so the value never reaches argv. ROW_PW is still set (redact()
  # uses it to scrub the tag's value out of anything emcli echoes back).
  local p="${F[$C_TYPE]}_" out=""
  ROW_PW="${F[$C_PW]:-$MON_PW}"
  out="${p}username:${F[$C_USER]:-$USERNAME_DEFAULT};${p}password:$CRED_PW_TAG"
  CREDS_STR="$out"
}
# ensure_cred_tmpdir: creates the private (mode 700) temp dir once and
# registers its cleanup trap. Must be called directly, never as $(...) — a
# command substitution runs in a subshell, and a trap set inside one fires
# the moment THAT subshell exits (i.e. at once, deleting the dir before any
# file is written), not when the whole script exits. Found running this
# under `set -x`: cred_tmpfile used to do both jobs and every apply_row call
# died on "No such file or directory" writing to an already-removed dir.
ensure_cred_tmpdir() {
  [ -n "$CRED_TMPDIR" ] && return 0
  CRED_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/mysql-onboard-cred.XXXXXX") || die "cannot create a temp directory for -input_file credential files"
  chmod 700 "$CRED_TMPDIR" 2>/dev/null || true
  trap 'rm -rf "$CRED_TMPDIR"' EXIT
}
# cred_tmpfile: a fresh owner-only (mode 600, mktemp's default) temp file
# path inside $CRED_TMPDIR. CWE-214: this is what -input_file
# points at — see the CRED_TMPDIR comment near the top of the file for why a
# file, not argv. Safe to call via $(...): it only creates a file, no trap.
# Guards CRED_TMPDIR itself even though ensure_cred_tmpdir is always called
# first from mode_apply: if CRED_TMPDIR were ever empty when this runs,
# `mktemp "$CRED_TMPDIR/cred.XXXXXX"` silently becomes `mktemp /cred.XXXXXX`
# — as root that SUCCEEDS, writing the cleartext password to the filesystem
# root with no mode-700 parent and no EXIT trap covering it (review finding).
# Do not "fix" this by calling ensure_cred_tmpdir lazily from
# here instead — cred_tmpfile is called via $(...), and a trap set inside
# that subshell fires on the subshell's exit, not the script's; see the
# ensure_cred_tmpdir comment above for why that already bit this once.
cred_tmpfile() {
  [ -n "$CRED_TMPDIR" ] || { echo "cred_tmpfile: CRED_TMPDIR is not set (ensure_cred_tmpdir was not called)" >&2; return 1; }
  mktemp "$CRED_TMPDIR/cred.XXXXXX"
}
apply_row() {
  local name="${F[$C_NEW_NAME]}" type="${F[$C_TYPE]}" agent="${AGENT_OVERRIDE:-${F[$C_AGENT]}}" rc=0 credfile
  build_props; build_creds
  # properties=|| / ~ only: -credentials has no separator override on real
  # emcli (confirmed on EM 24ai — "-separator=credentials" is
  # rejected outright with "not an option name registered to allow
  # specifying separators"), so passing one for it fails add_target/
  # modify_target before any name-value pair is even parsed.
  local sep=(-separator='properties=||' -subseparator='properties=~')
  # CWE-214: the password lives in this file, not in argv — see
  # the CRED_TMPDIR / cred_tmpfile comments. -properties (PROPS_STR, which
  # carries the licence key for a database row) has no such option on real
  # emcli and stays on the command line unchanged.
  # Under --dry-run the file is never created and the password is never
  # written to disk (review finding: --dry-run is the rehearsal
  # operators are told to run first, and used to write the real password to
  # a temp file even though it never calls emcli) — credfile is a plausible,
  # never-created path (mktemp -u) so the logged command line reads the same
  # either way, without the write.
  if [ "$DRY_RUN" = 0 ]; then
    credfile=$(cred_tmpfile) || { log "FAIL $name: cannot create a temp credential file"; n_failed=$((n_failed+1)); ROW_PW=""; return 0; }
    printf '%s' "$ROW_PW" > "$credfile" || { rm -f "$credfile" 2>/dev/null; log "FAIL $name: cannot write temp credential file"; n_failed=$((n_failed+1)); ROW_PW=""; return 0; }
  else
    credfile=$(mktemp -u "$CRED_TMPDIR/cred.XXXXXX")
  fi
  local infile=(-input_file="${CRED_PW_TAG}:${credfile}")
  run_emcli "add $name" add_target -name="$name" -type="$type" -host="$agent" -properties="$PROPS_STR" -credentials="$CREDS_STR" "${sep[@]}" "${infile[@]}" || rc=$?
  if [ "$rc" = 0 ]; then
    log "OK   $name: created"; n_created=$((n_created+1))
  elif [[ "$EMCLI_OUT" == *"already exists"* ]]; then
    rc=0; run_emcli "modify $name" modify_target -name="$name" -type="$type" -properties="$PROPS_STR" -credentials="$CREDS_STR" "${sep[@]}" "${infile[@]}" -on_agent || rc=$?
    if [ "$rc" = 0 ]; then log "OK   $name: exists, properties re-pushed (-on_agent)"; n_updated=$((n_updated+1)); else log "FAIL $name: modify_target rc=$rc: $(redact "$EMCLI_OUT" "$ROW_PW")"; n_failed=$((n_failed+1)); fi
  elif [[ "$EMCLI_OUT" == *"Dynamic Category property error"* ]]; then
    log "WARN $name: created; dynamic properties resolve on first collection"; n_created=$((n_created+1)); n_warned=$((n_warned+1))
  else
    log "FAIL $name: add_target rc=$rc: $(redact "$EMCLI_OUT" "$ROW_PW")"; n_failed=$((n_failed+1))
  fi
  [ "$DRY_RUN" = 0 ] && rm -f "$credfile"
  ROW_PW=""
  return 0
}
mode_apply() {
  check_csv_perms "$CSV"; load_passwords
  VALIDATION_ERRS=""; for_each_row "$CSV" row_validate
  [ -z "$VALIDATION_ERRS" ] || die "$CSV: fix these rows first (no emcli call was made):"$'\n'"$VALIDATION_ERRS"
  ensure_cred_tmpdir
  for_each_row "$CSV" apply_row
  summary
}
# target_status <name> <type>: Up/Down/… from get_targets, empty if unknown.
# The run_emcli_ro call is redirected to /dev/null: target_status is always
# read via command substitution (st=$(target_status …)), and log()'s own
# "RUN …" echo to stdout would otherwise be captured as part of the return
# value, corrupting the [ "$st" = Up ] comparison (defect found running the
# contract green — the file log via --log is unaffected, since log() appends
# to $LOG with its own explicit redirect regardless of our stdout redirect).
target_status() {
  local rc=0
  run_emcli_ro "status $1" get_targets -targets="$1:$2" -format="name:csv" >/dev/null || rc=$?
  [ "$rc" = 0 ] || { printf ''; return 0; }
  printf '%s\n' "$EMCLI_OUT" | awk -F, 'NR==2 {print $2}'
}
# license_status <name>: the License metric's "status" value (Active / License
# Required). get_metric_data's own Entity Name/Type columns can themselves be
# a target name with embedded spaces (e.g. "mysql84-2 (july84 SECONDARY)"),
# which shifts "status" off a fixed field number — parse by the literal
# " status  Status " token pair instead of by field position. Same
# stdout redirect as target_status, for the same command-substitution reason.
# On a non-zero emcli rc, report the failure itself ("emcli rc=<rc>")
# rather than falling through to the awk parse, which would print nothing
# and be indistinguishable in the verify table from a genuine empty read.
license_status() {
  local rc=0
  run_emcli_ro "license $1" get_metric_data -target_name="$1" -target_type=ip_mysql_database -metric_name=License >/dev/null || rc=$?
  [ "$rc" = 0 ] || { printf 'emcli rc=%s\n' "$rc"; return 0; }
  # Lab defect (EM 24ai): emcli's default "name:pretty"
  # table pads every column, including the last, to a fixed width — the
  # captured value is "Active<trailing spaces>", not "Active". Without the
  # trailing sub() below, verify_row's `[ "$lic" = Active ]` exact match
  # silently fails on every real emcli call, printing STATUS=Up LICENCE=
  # Active in the table (the untrimmed value still *looks* right) while the
  # VERDICT column stays FAIL — a genuinely licensed target never passes.
  # The hand-written hermetic fixture (license.txt) has no such padding, so
  # this never showed up under `make test-onboard`.
  printf '%s\n' "$EMCLI_OUT" | awk '/ status +Status +/ { sub(/.* status +Status +[0-9-]+ [0-9:]+ +/, ""); sub(/[ \t]+$/, ""); print; exit }'
}
verify_row() {
  local name="${F[$C_NEW_NAME]}" type="${F[$C_TYPE]}" st="" lic="-" t0 waited=0 verdict=FAIL remaining
  t0=$(date +%s)
  while :; do
    st=$(target_status "$name" "$type")
    if [ "$st" = Up ]; then
      if [ "$type" = ip_mysql_database ]; then lic=$(license_status "$name"); [ "$lic" = Active ] && verdict=PASS; else verdict=PASS; fi
    fi
    [ "$verdict" = PASS ] && break
    waited=$(( $(date +%s) - t0 ))
    # Never sleep a full 15s when less of the budget remains — costs
    # ~1s per failing row at --timeout 1, not fifteen.
    remaining=$(( TIMEOUT - waited )); [ "$remaining" -le 0 ] && break
    sleep $(( remaining < 15 ? remaining : 15 ))
  done
  printf '%-40s %-20s %-6s %-18s %-4s %4ss\n' "$name" "$type" "${st:-unknown}" "$lic" "$verdict" "$waited"
  if [ "$verdict" = PASS ]; then n_created=$((n_created+1)); else n_failed=$((n_failed+1)); fi
}
mode_verify() {
  printf '%-40s %-20s %-6s %-18s %-4s %5s\n' TARGET TYPE STATUS LICENCE VERDICT WAITED
  for_each_row "$CSV" verify_row
  # verify keeps counting in n_created/n_failed (so the exit code stays
  # n_failed) but skips the generic summary(), which would log this as
  # "created=N" — misleading in an audit trail for a read-only check.
  log "SUMMARY verify: passed=$n_created failed=$n_failed"
  exit_failed
}
associate_row() {
  [ "${F[$C_TYPE]}" = ip_mysql_database ] || return 0
  local name="${F[$C_NEW_NAME]}" std rc
  for std in "${STANDARDS[@]}"; do
    rc=0; run_emcli "associate $std → $name" associate_cs_targets -name="$std" -version=1 -author=INTEGRATION_PLUMBERS -target_list="$name" || rc=$?
    if [ "$rc" = 0 ]; then n_created=$((n_created+1))
    elif [[ "$EMCLI_OUT" == *"already associated"* ]]; then log "SKIP $name: $std already associated"; n_skipped=$((n_skipped+1))
    else log "FAIL $name: $std rc=$rc: $(redact "$EMCLI_OUT")"; n_failed=$((n_failed+1)); fi
  done
}
mode_associate() { for_each_row "$CSV" associate_row; summary; }
retire_row() {
  local src="${F[$C_SRC_NAME]}" stype="${F[$C_SRC_TYPE]}" name="${F[$C_NEW_NAME]}" type="${F[$C_TYPE]}" st rc=0
  [ -n "$src" ] || { n_skipped=$((n_skipped+1)); return 0; }
  st=$(target_status "$name" "$type")
  if [ "$st" != Up ]; then log "FAIL $src: replacement $name is ${st:-unknown}, not Up — not retiring"; n_failed=$((n_failed+1)); return 0; fi
  if [ "$YES" != 1 ]; then log "PLAN delete_target $src ($stype) — replacement $name is Up; re-run with --yes to execute"; n_skipped=$((n_skipped+1)); return 0; fi
  run_emcli "retire $src" delete_target -name="$src" -type="$stype" || rc=$?
  if [ "$rc" = 0 ]; then log "OK   $src: retired"; n_created=$((n_created+1)); else log "FAIL $src: delete_target rc=$rc: $(redact "$EMCLI_OUT")"; n_failed=$((n_failed+1)); fi
}
mode_retire() { for_each_row "$CSV" retire_row; log "SUMMARY retire: retired=$n_created skipped=$n_skipped failed=$n_failed"; exit_failed; }

# --- main ---
[ $# -ge 1 ] || { usage >&2; exit 2; }
case "$1" in -h|--help) usage; exit 0;; export|apply|verify|associate|retire) MODE="$1"; shift;; *) echo "ERROR: unknown mode '$1'" >&2; usage >&2; exit 2;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --csv) CSV="$2"; shift 2;;            --out) OUT="$2"; shift 2;;
    --source) SOURCE="$2"; shift 2;;      --force) FORCE=1; shift;;
    --dry-run) DRY_RUN=1; shift;;         --yes) YES=1; shift;;
    # a non-numeric --timeout would otherwise reach verify_row's arithmetic and
    # abort mid-poll, after emcli calls have already been made
    --timeout) TIMEOUT="$2"; case "$TIMEOUT" in ''|*[!0-9]*) die "--timeout must be a non-negative integer number of seconds, not '$TIMEOUT'";; esac; shift 2;;
    --agent) AGENT_OVERRIDE="$2"; shift 2;;
    --log) LOG="$2"; shift 2;;            --emcli) EMCLI="$2"; shift 2;;
    --password-env) PW_ENV="$2"; shift 2;; --ts-password-env) TSPW_ENV="$2"; shift 2;;
    --username) USERNAME_DEFAULT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "unknown option '$1'";;
  esac
done
[ -z "$LOG" ] && LOG="./mysql-onboard-$MODE-$(date -u '+%Y%m%dT%H%M%SZ').log"
# Probe the log now, not on the first log() append: log() deliberately swallows
# its own append failure (return 0) so a logging problem can never abort a run
# mid-estate, which means an unwritable --log would otherwise run the whole
# migration and record none of it. Create it owner-only — the log holds
# every emcli command line, and those carry licence keys.
( umask 077; : >> "$LOG" ) || die "cannot write log $LOG"
case "$MODE" in
  export) [ -n "$OUT" ] || die "export needs --out FILE";;
  *)      [ -n "$CSV" ] || die "$MODE needs --csv FILE"; validate_csv "$CSV";;
esac
require_session
"mode_$MODE"
