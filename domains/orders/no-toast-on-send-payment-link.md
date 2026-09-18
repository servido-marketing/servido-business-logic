---
id: orders-no-toast-on-send-payment-link
domain: orders
title: Manager panel does not show a success toast when "Send payment link" completes
status: active
applies_to: [manager]
tags: [orders, payments, payment-link, manager, toast, ux]
path: domains/orders/no-toast-on-send-payment-link.md
created: 2026-08-11
---

## Rule

In the manager panel task details screen, triggering `sendPaymentLink` (the
"Send payment link" action) must NOT show a success toast on completion.

## Rationale

The manager clicks "Send payment link" repeatedly while working a task and the
confirmation toast is noise — the action's effect (link sent) is not something
the manager needs re-confirmed every time via a toast. All other actions on
this screen (save, savePrice, saveProviderReward, saveDeduction, saveSchedule,
savePaymentMark) keep their existing success toasts; only `sendPaymentLink` is
exempted.

## Scope

- `bond_manager_task_details.dart`: remove the
  `ShowSuccessToast(whenActionSucceeds: bloc.bloc.sendPaymentLink, message: l10n.linkSent)`
  entry from the action-toast list. No other action's toast wiring changes.
- Error handling (`ShowErrorPopup`) on failure remains unchanged — only the
  success toast is suppressed.
