---
id: website-description-field-truncate-expand
domain: website
title: Long free-text detail fields collapse to one line with an expand toggle
status: active
applies_to: [web]
tags: [website, gig, task, description, details, truncate, expand, ui]
supersedes: []
created: 2026-08-10
updated: 2026-08-10
---
## Rule
Any customer-facing free-text field on the website whose content length is unbounded (e.g. gig
"description"/"details" on the account task-detail view) MUST render collapsed to a single line
by default, truncated with an ellipsis, with a text button ("Show more" / "Show less") that
toggles between collapsed (1 line) and fully expanded display. Short text that already fits on
one line MUST NOT show the toggle at all.

## Rationale
Long free-text descriptions were consuming disproportionate vertical space on the task detail
page, pushing other fields (schedule, address, provider, credits) below the fold. Collapsing by
default keeps the field list compact while still letting the customer read the full text on
demand.

## Implementation
- Applies to `servido-website/src/components/account/TaskDetail.tsx`'s description `Field`
  (value derived from `task.details` / `task.description[lang]`).
- Detect overflow via CSS line-clamp (`line-clamp-1` / `-webkit-line-clamp: 1`) rather than a
  hardcoded character count, so it degrades correctly across languages/fonts.
- Toggle state is local component state (`useState`), collapsed by default.
- The toggle button only renders when the text is actually clamped (overflowing) — for that,
  either measure `scrollHeight > clientHeight` after render, or use a conservative character-count
  heuristic (e.g. >80 chars) as a same-render fallback if DOM measurement is impractical.
- Use existing i18n keys pattern; add `account.detail.showMore` / `account.detail.showLess` (fi/en)
  translation keys — do not hardcode English strings.

## Verification
On the account task-detail page, a description longer than one line renders truncated with a
"Show more" button; clicking it reveals the full text and the button now reads "Show less";
clicking again re-collapses it. A description short enough to fit one line shows no button.
