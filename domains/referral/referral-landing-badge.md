---
id: referral-referral-landing-badge
title: Referral landing badge — show 10 EUR discount when arriving via share link
status: active
domain: referral
applies_to: [web]
tags: [referral, share, discount, badge, landing, website, ux]
created: "2026-07-01"
---

## Rule

When a visitor arrives at any page of the website with a `?ref=<code>` query parameter, the site MUST display a persistent discount badge informing them they have a 10 EUR credit that will be applied automatically when they place their first order.

The badge MUST:
- Appear as soon as the page loads (before any user action)
- State the exact discount amount: 10 EUR
- Make clear the discount is tied to the referral (someone shared the link with them)
- Persist across navigation within the site session (stored in sessionStorage alongside `servido_ref`)
- Be dismissible by the user (dismiss hides it for the session)

The badge MUST NOT:
- Require login to show
- Show if no `ref=` param is present (and no `servido_ref` in sessionStorage)
- Block content or require the user to interact before seeing the page

## Rationale

The referral credit of 10 EUR (1000 cents) is already granted by the backend (stripeWebHook) when the referred customer completes their first payment. However, the customer currently has no visual confirmation they received a discount when they land via a share link. Without this badge, referral conversion suffers because users don't know why they should prefer Servido through this link vs. finding it directly.

## Implementation

1. `Layout.astro` already captures `?ref=` into `sessionStorage.servido_ref`. The badge logic reads from `sessionStorage` too — no extra server round-trip needed.
2. A client-side React island `ReferralBadge.tsx` renders the badge when `sessionStorage.servido_ref` is set. It uses a `client:load` directive so it appears on every page.
3. The badge shows: a gift/discount icon, copy like "Sinulla on 10 € alennus käytettävissäsi tällä tilauksella" (fi) / "You have a €10 discount on your first order" (en), and a dismiss ×.
4. Dismiss state: `sessionStorage.setItem('servido_ref_badge_dismissed', '1')` — so the badge re-appears on fresh sessions (which is correct — a new tab via the same ref should show it again).
5. The badge is mounted in `Layout.astro` just before `</body>`.

## Verification

- Visit any page with `?ref=TESTCODE` → badge appears with "10 €" visible.
- Dismiss the badge → badge disappears; navigating to another page does NOT re-show it (session dismissed).
- Open a new tab with `?ref=TESTCODE` → badge re-appears (dismiss is per-tab session).
- Visit the page WITHOUT `?ref=` and no prior sessionStorage → badge does NOT appear.
