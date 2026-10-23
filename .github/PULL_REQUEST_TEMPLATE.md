## Summary
<!-- what & why, 2–4 sentences. Name the product section(s) touched. -->

## Monday task
<!-- link — resolved from the branch, or created inline; for a Self-merge change this may be `no task — <reason>` -->

## Risk / review tier
<!-- two-class model from .github/risk-classes.yml: Self-merge (a product's own
     pages / images / nav) or Reviewed (default — site/, CNAME,
     scripts/, .github/, anything shared across sections). -->
**<Reviewed | Self-merge>** — basis: <!-- the self_merge glob that matched, or "default (not on self_merge allowlist)" --> (a human may raise it, never lower it)

## Authorship
<!-- human | AI-assisted | autonomous agent --> — Agent Instructions: <!-- link or n/a -->

## AI pre-review triage
<!-- page content: consistency + secrets pass, and the static-checks run (lint-docs + check-anchors) is green.
     site / scripts / workflow diffs: /code-review + /security-review. -->
| Finding | Source | Resolution |
|---|---|---|
| <finding> | code-review / security-review / lint | fixed (<commit>) / dismissed: <reason> |

## Verification evidence
<!-- for page content: the rendered page checked locally (cd site && npm run build && npm run preview) or the static-checks run link;
     otherwise "not applicable (docs site — no lab gate)" -->

## Rollback
<!-- usually "revert the squash commit"; GitHub Pages republishes main on the next push -->
