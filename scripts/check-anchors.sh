#!/usr/bin/env bash
# Verify every relative `page.md#anchor` link in postgresql/*.md resolves to a heading in the target page.
# Heading ids: an explicit kramdown IAL `{#id}` wins; otherwise the id GitHub Pages renders for
# this site, which is kramdown's GFM parser's: lowercase, drop chars other than [A-Za-z0-9_ -],
# spaces->hyphens, and LEADING DIGITS ARE KEPT ("7.1 Default thresholds" -> 71-default-thresholds).
# Verified 2026-09-29 against every MySQL heading on the live site (322/322); the old
# strip-leading-non-letters rule missed 56 and agreed with 162 links that resolved nowhere.
# Usage: scripts/check-anchors.sh [file ...]   (default: postgresql/*.md). Exit 1 on any unresolved anchor.
set -u
cd "$(dirname "$0")/.."
FILES=("$@"); [[ ${#FILES[@]} -eq 0 ]] && FILES=(postgresql/*.md)

ids_of() { # print all heading ids of a markdown file, one per line
  grep -E '^#{1,6} ' "$1" | while IFS= read -r h; do
    if [[ "$h" =~ \{#([A-Za-z0-9_-]+)\}[[:space:]]*$ ]]; then
      echo "${BASH_REMATCH[1]}"
    else
      t="${h#"${h%%[! #]*}"}"          # drop leading #'s and spaces
      t="$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_ -]//g; s/ /-/g')"
      echo "$t"
    fi
  done
}

rc=0
for f in "${FILES[@]}"; do
  while IFS= read -r link; do
    target="${link%%#*}"; anchor="${link#*#}"
    [[ "$link" != *"#"* ]] && continue
    [[ "$target" =~ ^(https?:|mailto:|/) ]] && continue
    if [[ -z "$target" ]]; then tf="$f"; else tf="$(dirname "$f")/$target"; fi
    if [[ ! -f "$tf" ]]; then echo "$f: link target missing: $target"; rc=1; continue; fi
    if ! ids_of "$tf" | grep -qx "$anchor"; then echo "$f: anchor not found: $target#$anchor"; rc=1; fi
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\((.*)\)$/\1/; s/ "[^"]*"$//')
done
[[ $rc -eq 0 ]] && echo "all anchors resolve"
exit $rc
