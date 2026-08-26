#!/usr/bin/env bash
# Lint the PostgreSQL guide pages: front matter, forbidden terms, relative links, images.
# Usage: scripts/lint-docs.sh [--allow-missing-images] [file ...]     (default: postgresql/*.md)
# Exit 1 on any finding except "pending image" / "pending CONFIRM" when --allow-missing-images is set.
set -u
cd "$(dirname "$0")/.."
ALLOW=0
if [[ "${1:-}" == "--allow-missing-images" ]]; then ALLOW=1; shift; fi
FILES=("$@")
[[ ${#FILES[@]} -eq 0 ]] && FILES=(postgresql/*.md)

# Terms that must never appear in customer-facing pages (internal markers, roadmap/season language,
# retired names, unshipped features, unverified claims, placeholders).
FORBID='\[INTERNAL|INTERNAL:|Winter|24\.1\.2|\bPRD\b|roadmap|Query Advisor|Plan Capture readiness|one-click|Disk Sort|Hash Batches|Expensive Node|Large Offset|arrives in|next release|coming soon|planned for|\bTBD\b|\bTODO\b|encrypted at rest|Lorem ipsum|\bSummer\b|Tier 0/1|Tier 2/3|\bOEM\b'

rc=0
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "$f: not found"; rc=1; continue; }
  if [[ "$(head -1 "$f")" != "---" ]]; then echo "$f: missing front matter"; rc=1; fi
  if grep -nE "$FORBID" "$f"; then echo "$f: forbidden term(s) above"; rc=1; fi
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
      if [[ "$t" =~ \.(png|gif|jpg)$ && $ALLOW -eq 1 ]]; then echo "$f: pending image $t"
      else echo "$f: broken link $t"; rc=1; fi
    fi
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\((.*)\)$/\1/; s/ "[^"]*"$//')
done
exit $rc
