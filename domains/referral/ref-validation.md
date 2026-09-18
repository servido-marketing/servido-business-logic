---
id: referral-ref-validation
domain: referral
title: Referral code MUST be validated server-side before being stored or displayed
status: active
applies_to: [web]
tags: [referral, validation, hotline, backend, website, security]
supersedes: []
created: 2026-07-02
updated: 2026-07-02
---

## Rule

When a visitor arrives with a `?ref=<code>` query param, the website MUST validate the
code via the `validateRef` hotline endpoint before storing it in sessionStorage or showing
the referral badge. Any code that fails validation MUST be discarded — never stored, never
displayed.

A ref code is VALID if and only if ALL of the following hold:

1. **Exists** — a customer doc exists with `referralCode == code` in the `customers`
   collection.
2. **Not self-ref** — the logged-in user (if any) is not the owner of the referral code.
   If the visitor is anonymous, this check is skipped (self-ref is re-checked at payment).
3. **Referee is eligible** — the current user has zero prior BOOKED tasks. "Booked" means
   the `tasks` collection contains at least one doc where `customer == uid` AND the events
   array includes any of the payment-success event kinds
   (`TaskPaymentSuccessEvent`, `TaskPaymentVerificationSuccessEvent`,
   `TaskPaymentMethodSetupSuccessEvent`). The `isBooked` flag on the customer profile MUST
   NOT be used — it is unreliable. For anonymous visitors this check is skipped (checked
   again at payment).

A code that fails any check is silently discarded: the sessionStorage key `servido_ref`
is NOT set and the referral badge is NOT shown.

## Rationale

Currently `?ref=<any-garbage>` is captured blindly into sessionStorage and the badge
fires for any non-empty string. This lets users share nonsense URLs that show a valid-
looking referral badge with no underlying discount. The validation gate ensures only
legitimate referral codes enter the session.

The "first booking" eligibility is checked AGAIN by the backend at payment time
(self-healing), so the frontend check is a best-effort UX gate: it keeps the badge
accurate without being the security boundary.

## Implementation

Backend (`cf/functions/src/validateRef.ts`):
- New hotline handler `handleValidateRef` exported and registered in `customerHotline.ts`.
- Request: `{ code: string }`.
- Response: `{ valid: boolean }`.
- Logic:
  1. Look up `customers` where `referralCode == code`, limit 1. If empty → `{ valid: false }`.
  2. If caller is authenticated (`request.auth?.uid`) and `referrerId === callerId` → `{ valid: false }` (self-ref, logged-in case).
  3. If caller is authenticated, count the caller's tasks with a payment-success event. If count > 0 → `{ valid: false }` (not first booking).
  4. Otherwise → `{ valid: true }`.
- Does NOT require auth (`guard.consume` skipped — anonymous callers must be able to validate). Use `request.auth?.uid` safely.

Website (`src/layouts/Layout.astro`):
- Replace the current blind sessionStorage write with an async call:
  `callable('validateRef', { code: _ref }).then(res => { if (res?.valid) sessionStorage.setItem('servido_ref', _ref); })`.
- The badge component already reads from sessionStorage so it shows only if the write succeeded.

## Verification

- `?ref=shit` → badge MUST NOT appear (no matching customer doc).
- `?ref=<own-code>` when logged in → badge MUST NOT appear (self-ref).
- `?ref=<own-code>` when anonymous → badge MAY appear (self-ref checked at payment).
- `?ref=<valid-code>` with a prior paid booking on the account → badge MUST NOT appear.
- `?ref=<valid-code>` with no prior paid booking → badge MUST appear.
