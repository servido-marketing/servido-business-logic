---
id: auth-manager-suspend-provider
domain: auth/manager
title: Manager MUST be able to suspend (disable) and reactivate a service provider at the auth level
status: active
applies_to: [web, all]
tags: [auth, manager, provider, suspend, disable, deactivate, activate, panel, providers-list]
supersedes: []
created: 2026-08-23
updated: 2026-08-23
---
## Rule
A manager MUST be able to disable and re-enable a service provider's account from the
Providers list in the manager panel. Disabling a provider MUST disable their Firebase Auth
account (`disabled: true`) so the provider immediately loses the ability to sign in — this is
an auth-level suspension, not a soft-delete/hide. Re-enabling MUST clear the auth `disabled`
flag and restore login. The Providers list MUST visually indicate a provider's disabled state
(e.g. dimmed row + "Disabled" label, mirroring the existing `isDeleted` treatment on the
Customers list). Disabling MUST NOT delete the provider's Firestore profile, tasks, or history
— it only gates authentication, exactly like a temporary suspension, not `deleteCustomer`'s
permanent removal.

## Rationale
Managers need a reversible way to stop a problematic provider from working (policy violation,
investigation, fraud, no-show pattern) without the irreversible destructiveness of full
deletion (`deleteCustomer`/an eventual `deleteProvider` also hard-deletes the Firebase Auth
user). A dedicated suspend/activate toggle gives managers a middle ground: block access now,
restore it later if warranted, with a clear visual signal of which providers are currently
suspended.

## Implementation
- New provider entity field `disabled: bool` (mirrors `Customer.isDeleted`'s pattern: stored on
  the Firestore `providers/{id}` doc, mapped into `ServiceProvider`/`ProviderProfile`).
- Two callables, modeled on `deleteCustomer` (`cf/functions/src/deleteCustomer.ts`) but NOT
  reusing it (that one hard-deletes):
  - `suspendProvider({ provider })`: `guard.manage(request)`, then
    `admin.firestore().collection('providers').doc(id).set({ disabled: true }, { merge: true })`
    followed by `admin.auth().updateUser(id, { disabled: true })`.
  - `activateProvider({ provider })`: same guard, sets `disabled: false` on the Firestore doc,
    then `admin.auth().updateUser(id, { disabled: false })`.
  - Firestore write MUST happen before the Auth SDK call is awaited in each case so an Auth SDK
    failure doesn't leave state inconsistent silently (mirrors `deleteCustomer`'s ordering).
- `ProvidersListPartial`'s `DesktopProviderRow` gets its dropdown/menu wired (currently a
  disabled/commented-out `buildDropdownButton` call) with "Deactivate"/"Activate" menu actions
  depending on current `disabled` state, following `DesktopCustomerRow`'s `makeMenuItems` +
  `buildDropdownButton` pattern exactly.
- Row visual state mirrors `DesktopCustomerRow`'s `isDeleted` treatment: `Opacity(opacity: disabled
  ? 0.39 : 1)` plus a disabled/"Suspended" label rendered where the row currently shows the
  dropdown for a deleted customer.
- `BondProvidersBloc`/`ProvidersListBloc` wires the two new actions the same way
  `BondCustomersBloc` wires `bloc.delete.result` — optimistic local mutate + backend call.

## Verification
Proof/manual check: (a) a manager clicks "Deactivate" on a provider row → the row immediately
dims and shows a disabled indicator, and the provider's Firebase Auth user has `disabled: true`
(a login attempt as that provider fails); (b) clicking "Activate" on a disabled provider clears
the auth `disabled` flag and login succeeds again; (c) the provider's Firestore profile document
and task history remain fully intact through both operations — no data is deleted.
