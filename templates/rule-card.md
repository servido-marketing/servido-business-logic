---
id: DOMAIN-short-slug            # unique, kebab-case, stable forever (never reuse)
domain: auth/common             # path under domains/ this card lives in
title: One-line imperative rule
status: active                  # active | superseded | deprecated
applies_to: [web, mobile, all]  # which surfaces this binds; use [all] if universal
tags: [auth, login]             # free-form, lowercase; used for pull-time grep
supersedes: []                  # list of card ids this replaces (set status of those -> superseded)
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
## Rule
The binding statement. MUST/MUST NOT language. One rule per card.

## Rationale
Why this rule exists. Conversion data, parity with another app, legal, UX — the "why" so a
future agent doesn't "optimize" it away.

## Implementation
Concrete guidance: exact order, component names, edge cases, what counts as compliant.
Keep app-agnostic where possible; note per-surface differences under applies_to.

## Verification
How a worker proves compliance. Phrase as an assertion the proof spec can check
(e.g. "screenshot shows social buttons above the email field"). This line becomes a
permanent regression check when pulled into a new app.
