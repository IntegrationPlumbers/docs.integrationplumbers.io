#!/usr/bin/env bash
# Lint a product's guide pages: front matter, forbidden terms, relative links, images (markdown links and <video src/poster>).
# Usage: scripts/lint-docs.sh [--allow-missing-images] [file ...]     (default: postgresql/*.md)
# Exit 1 on any finding except "pending image" / "pending CONFIRM" when --allow-missing-images is set.
set -u
cd "$(dirname "$0")/.."
ALLOW=0
if [[ "${1:-}" == "--allow-missing-images" ]]; then ALLOW=1; shift; fi
FILES=("$@")
[[ ${#FILES[@]} -eq 0 ]] && FILES=(postgresql/*.md)

# Forbidden terms are split shared vs per-product. The shared list is what is wrong in
# ANY product's customer docs: internal markers, roadmap language, placeholders,
# over-claims. The per-product lists hold that product's unshipped feature names and
# release-season vocabulary, which mean nothing in another guide and produced false
# positives when applied to all of them.
#
# SHARED + FORBID_postgresql is exactly the single list this replaced, so the
# PostgreSQL gate is unchanged.
FORBID_SHARED='\[INTERNAL|INTERNAL:|\bPRD\b|roadmap|arrives in|next release|coming soon|planned for|\bTBD\b|\bTODO\b|Lorem ipsum|one-click|\bOEM\b'
FORBID_postgresql='Winter|\bSummer\b|24\.1\.2|Query Advisor|Plan Capture readiness|Disk Sort|Hash Batches|Expensive Node|Large Offset|encrypted at rest|Tier 0/1|Tier 2/3'
FORBID_mssql=''
FORBID_mysql=''

# Approved copy that a lint rule must not silently rewrite. A phrase listed here is
# blanked before the file is linted, so any OTHER forbidden term on the same line is
# still caught.
#   mysql/beta-pre-release.md - Open Beta terms of use; wording approved by Nathan,
#   Chris and Cam (2026-08-31). "planned for late 2026" and "planned for a later
#   release" are deliberate and are not ours to reword.
exempt_for() {
  case "$1" in
    mysql/beta-pre-release.md) printf '%s' 'planned for' ;;
    *) printf '%s' '' ;;
  esac
}

forbid_for() {
  case "$(dirname "$1")" in
    postgresql) printf '%s|%s' "$FORBID_SHARED" "$FORBID_postgresql" ;;
    mssql)      printf '%s' "$FORBID_SHARED" ;;
    mysql)      printf '%s' "$FORBID_SHARED" ;;
    *)          printf '%s|%s' "$FORBID_SHARED" "$FORBID_postgresql" ;;
  esac
}

rc=0
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "$f: not found"; rc=1; continue; }
  if [[ "$(head -1 "$f")" != "---" ]]; then echo "$f: missing front matter"; rc=1; fi
  FORBID="$(forbid_for "$f")"
  EXEMPT="$(exempt_for "$f")"
  # blank exempted phrases first (line count preserved, so line numbers stay true)
  if [[ -n "$EXEMPT" ]]; then SRC="$(sed -E "s/$EXEMPT//g" "$f")"; else SRC="$(cat "$f")"; fi
  if printf '%s\n' "$SRC" | grep -nE "$FORBID"; then echo "$f: forbidden term(s) above"; rc=1; fi
  # Final gate: CONFIRM placeholders must be resolved before publish. Tolerated only
  # while --allow-missing-images marks the run as a pre-capture draft check.
  while IFS= read -r n; do
    if [[ $ALLOW -eq 1 ]]; then echo "$f: pending CONFIRM (line $n)"
    else echo "$f: unresolved CONFIRM placeholder (line $n)"; rc=1; fi
  done < <(grep -n "CONFIRM:" "$f" | cut -d: -f1)
  while IFS= read -r link; do
    t="${link%%#*}"
    [[ -z "$t" ]] && continue
    [[ "$t" =~ ^(https?:|mailto:|/) ]] && continue
    p="$(dirname "$f")/$t"
    if [[ ! -e "$p" ]]; then
      if [[ "$t" =~ \.(png|gif|jpg|mp4)$ && $ALLOW -eq 1 ]]; then echo "$f: pending image $t"
      else echo "$f: broken link $t"; rc=1; fi
    fi
  done < <({ grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\((.*)\)$/\1/; s/ "[^"]*"$//'; grep -oE '(src|poster)="[^"]+"' "$f" | sed -E 's/^(src|poster)="(.*)"$/\2/'; })
done
exit $rc
