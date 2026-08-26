#!/usr/bin/env bash
# Verify every relative `page.md#anchor` link in postgresql/*.md resolves to a heading in the target page.
# Heading ids: an explicit kramdown IAL `{#id}` wins; otherwise the kramdown auto-id
# (strip leading non-letters, drop chars other than [A-Za-z0-9 -], spaces->hyphens, lowercase).
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
      t="$(printf '%s' "$t" | sed -E 's/^[^A-Za-z]+//; s/[^A-Za-z0-9 -]//g; s/ /-/g' | tr '[:upper:]' '[:lower:]')"
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
