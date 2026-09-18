---
id: orders-payment-link-refresh-on-validation
domain: orders
title: Manager payment links must be refreshed with phone number when TaskValidated arrives
status: active
applies_to: [all]
supersedes: []
created: 2026-07-07
updated: 2026-07-07
tags: [orders, payments, payment-link, mobilepay, phone, validation, manager]
---

## Rule

When a `TaskValidated` event is folded into the manager task projection (`deriveManagerState`),
the `paymentLink`, `paymentVerificationLink`, and `paymentExtensionLink` fields MUST be
regenerated using the phone number carried on that event, replacing whatever links were computed
at initial booking time.

## Rationale

Payment links are generated once, at the initial booking event (`TaskBookedFromMarketplaceService`,
`TaskBookedFromLocalService`, `RegisterConversion`, `GigIntiatedAsProvider`), using
`task.customer?.phoneNumber` at that point in the fold. For the marketplace/local-service flows,
the customer's phone number is not known yet at booking time — it is collected later and attached
to the task via the `TaskValidated` event (see `stateDeriver.ts`, `TaskValidated` branch in
`deriveManagerState`, which already updates `task.customer` but does NOT rebuild the payment
links). The result: the manager's payment link/MobilePay flow never receives the phone number even
though `orders-mobilepay-phone-prefill` says it should, because the links generated at booking are
never regenerated after the phone becomes known. This card fixes the actual root cause of that gap.

## Implementation

In `cf/functions/src/utils/stateDeriver.ts`, function `deriveManagerState`, `TaskValidated`
branch: after setting `task.customer`, also recompute the three link fields using the same
`makePaymentVerificationLink(taskId, ..., task.customer?.phoneNumber)` calls already used in the
initial-event branches:

```ts
} else if (event.kind === 'TaskValidated') {
    task.customer = {
        fullName: event.customer.fullName,
        email: event.customer.email,
        phoneNumber: event.customer.phoneNumber,
    };
    task.isBooked = true;
    task.paymentVerificationLink = makePaymentVerificationLink(taskId, false, false, false, false, false, task.customer?.phoneNumber);
    task.paymentLink = makePaymentVerificationLink(taskId, true, false, false, false, false, task.customer?.phoneNumber);
    task.paymentExtensionLink = makePaymentVerificationLink(taskId, false, true, false, false, false, task.customer?.phoneNumber);
    task.trace?.push({ base: event.base, kind: 'validated' });
    return;
}
```

No new events, no schema changes, no migrations needed — `TaskValidated` and the link-building
utility already exist; this only wires the phone through at the point it becomes known.

## Verification

For a task booked via `bookMarketplaceService` (or `bookLocalService`) WITHOUT a phone number at
booking time, then later validated via `validateTask` with a phone number supplied, the manager
task projection's `paymentLink`/`paymentVerificationLink`/`paymentExtensionLink` MUST contain that
phone number (via `&contact_phone=`) after the `TaskValidated` fold — not the phone-less link
generated at initial booking.
