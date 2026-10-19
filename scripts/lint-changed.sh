#!/usr/bin/env bash
# Run lint-docs.sh and check-anchors.sh over the product guides a change touches.
# Usage: scripts/lint-changed.sh [<base-ref>]     (default: origin/main)
#
# A "touched" product is one with a changed page anywhere under postgresql/, mysql/,
# mssql/ or db2/ (nested pages such as mysql/ai/*.md count). The WHOLE product
# directory is then linted, not just the changed pages:
# a page that was deleted or renamed breaks links in its neighbours, and only the
# full-directory pass sees that. Products the change does not touch are left
# alone, so a draft section can never hold up another product's publish.
# A change to either lint script re-lints every product.
# Exit 1 on any finding; exit 0 (with a note) when no guide page changed.
set -u
cd "$(dirname "$0")/.."
BASE="${1:-origin/main}"
PRODUCTS="postgresql mysql mssql db2"

CHANGED="$(git diff --name-only --diff-filter=ACMRD "$BASE...HEAD" -- 2>/dev/null)" || {
  echo "cannot diff against $BASE (fetch it first, or pass a base ref)"; exit 2; }

if printf '%s\n' "$CHANGED" | grep -qE '^scripts/(lint-docs|check-anchors)\.sh$'; then
  TOUCHED="$PRODUCTS"
else
  TOUCHED=""
  for p in $PRODUCTS; do
    if printf '%s\n' "$CHANGED" | grep -qE "^$p/.+\.md$"; then TOUCHED="$TOUCHED $p"; fi
  done
fi

if [[ -z "${TOUCHED// /}" ]]; then echo "no guide pages changed against $BASE - nothing to lint"; exit 0; fi

rc=0
for p in $TOUCHED; do
  # every page in the section, nested ones included (mysql/ai/*.md)
  PAGES="$(find "$p" -name '*.md' | sort)"
  echo "== $p: lint-docs"
  scripts/lint-docs.sh $PAGES || rc=1
  echo "== $p: check-anchors"
  scripts/check-anchors.sh $PAGES || rc=1
done
exit $rc
