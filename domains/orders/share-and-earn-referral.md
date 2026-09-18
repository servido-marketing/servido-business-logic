---
id: orders-share-and-earn-referral
domain: orders
title: Share-and-earn referral credits — both referrer and referee get 10 EUR
status: active
applies_to: [web, mobile]
tags: [referral, share, credits, discount, earn, invite, promo]
supersedes: []
created: 2026-06-30
updated: 2026-06-30
---
## Rule
A customer (referrer, customer A) MAY share a personal referral link. When a new
customer (referee, customer B) books via that link and their booking is paid, BOTH
the referrer and the referee MUST each receive 10 EUR referral credit added to their
account. Credits are stackable — a customer may accumulate credits from multiple
referrals. Credits MUST NOT expire.

A referral is only activated on the referee's first successful payment
(`TaskPaymentSuccessEvent`, `TaskPaymentVerificationSuccessEvent`, or
`TaskPaymentMethodSetupSuccessEvent`). If the referee abandons the booking or payment
fails, no credits are awarded.

Credits are applied automatically to the customer's next booking as a fixed-amount
discount, reducing the amount charged. The customer MUST be able to see their current
credit balance. A booking that costs less than the available credit balance MUST only
consume the credit amount equal to the booking price (no negative charge).

One referral link attribution per referee — a referee's second or subsequent bookings
do NOT award additional credits (the referral is a one-time event per referred user).

## Rationale
Referral credits are stackable and persistent (not one-time promo codes). They differ
from the existing promo code system: promo codes are manager-created, ephemeral, and
attached to a task via `applyPromoCode`. Referral credits are user-earned, stored on
the customer profile, and applied automatically at payment time.

## Implementation
- A new `referralCredits` field (number, EUR cents) on the customer profile Firestore
  document tracks the running balance.
- A new `referralLink` field (string, referral code) on the customer profile is the
  shareable token. Generated once per customer (e.g. UID-derived or random). Exposed
  to the customer via a `getMyReferralLink` callable.
- At booking flow start, the website accepts a `ref=<code>` query parameter and stores
  it in booking wizard state; the parameter is passed to `bookMarketplaceService` (or
  `bookLocalService`) via a new optional `referralCode` field in the request schema.
- The backend stores the `referralCode` on the task (a new `referralCode` field on the
  central task doc). On successful payment event, if the task has a `referralCode` and
  the referee has not been credited before (i.e. they have no prior task with a
  `referralCode` and a payment-success event), the callable MUST:
  1. Add 10 EUR (1000 cents) to the referrer's `referralCredits` balance.
  2. Add 10 EUR (1000 cents) to the referee's `referralCredits` balance.
  3. Append a `ReferralCreditGrantedEvent` to BOTH tasks (referrer's latest paid task
     for traceability, and the referee's current task).
- When a customer pays via the booking flow, the backend MUST automatically deduct
  available `referralCredits` from the charge amount (up to the full booking price).
  The deduction is recorded as a `referralCreditApplied` field on the payment event.
- Customers view their credit balance on their profile/account page (website + app).

## Verification
When referee B books via referrer A's link and pays:
  - Both A and B MUST have `referralCredits >= 1000` on their profile docs.
  - B's task MUST have a `referralCode` field on the task doc.
A second booking by the same referee B MUST NOT award additional credits to A.
A customer with credits booking again MUST have the credit deducted from the payment amount.
Credit balance MUST be visible in the customer account UI (website + app).
