---
id: referral-no-self-referral
domain: referral
title: Referral credit MUST NOT be granted when the referrer and referee are the same person
status: active
applies_to: [web, mobile, all]
tags: [referral, share, abuse, credit, identity, backend]
supersedes: []
created: 2026-07-02
updated: 2026-07-02
---

## Rule

A user MUST NOT receive referral credit (neither as referrer nor as referee) when they use
their own referral link to book a service. The backend MUST detect and reject self-referral
regardless of whether the referrer and referee have the same Firebase UID.

## Rationale

On the website, each booking session creates a new anonymous Firebase UID. A user can:
1. Copy their referral link (`?ref=<code>`) via the mobile app or account page.
2. Open it in a fresh browser session, which creates a NEW anonymous UID.
3. Complete a booking. The backend compares `referrerId !== customerId` (UID-based) — these
   differ (fresh anon UID vs. the user's real UID), so the check passes and they receive
   €10 credit for both roles.

Because identity on the website is ephemeral (anonymous), the self-referral guard MUST be
done at the identity-attribute level (email or phone), not the UID level.

## Implementation

In `stripeWebHook.ts`, inside the `processReferralAndApplyCredits` function, after resolving
the referrer document from `referralCode`:

1. Fetch both the referrer's customer doc and the booking customer's customer doc.
2. If the referrer doc has an `email` or `phone` field, compare it against the booking
   customer's corresponding field.
3. If either of the following is true, treat it as a self-referral and skip the grant:
   - `referrerId === customerId` (existing UID guard — keep it)
   - `referrerEmail !== undefined && referrerEmail === customerEmail`
   - `referrerPhone !== undefined && referrerPhone === customerPhone`
4. Do NOT proceed with `ReferralCreditGranted` events or credit balance updates when any of
   the above conditions is met.

The customer profile fields to compare are stored in `customers/{uid}` as `email` (string,
optional) and `phone` (string, optional), populated by `createProfile` / `updateProfile`.

## Verification

- A user copies their own referral link, opens it in a new browser session (new anon UID),
  and completes a booking to first payment. No `ReferralCreditGranted` event MUST appear on
  the task, and `customers/{uid}.referralCredits` MUST NOT increase.
- A genuinely different user uses the share link and pays → credits ARE granted as normal.
- The existing UID-equality guard still short-circuits before the attribute check (no double
  Firestore read on mobile where UID is stable).
