---
id: orders-manager-gig-money-edit-validation
domain: orders
title: Manager gig view money edits are validated, saved as one block, and never lose unsaved edits silently
status: active
applies_to: [web]
tags: [manager-panel, gig-view, pricing, provider-reward, validation, unsaved-changes, vat]
supersedes: []
created: 2026-10-11
updated: 2026-10-11
---
## Rule
In the manager gig view (task preview, manager role):
1. Money fields (customer price / unit price, provider reward, deducted price, per-provider reward override, additional product and additional work prices) MUST show a `€` prefix, display and edit in euros with exactly two decimals (comma or dot accepted as separator), and convert to integer cents only when saving.
2. A save MUST be rejected, without a confirmation dialog or override, when the provider reward (total, or any single provider override) is greater than the customer price it is paid out of, or when any money value is negative. The field shows an inline Finnish error and nothing is sent. Reward equal to the price is allowed. Deducted price greater than the customer price is rejected the same way.
3. The money inputs are saved with ONE save action per block: one for the providers block (all reward overrides) and one for the pricing block (price, reward, deduction, additional lines). There are no per-field save buttons. A block's save is disabled when it has no edits.
4. The view MUST show the number of unsaved edited fields (per block and in total in the header) and MUST warn (confirm leave / stay) before leaving the gig view while any edit is unsaved. Browser close/refresh is covered by the browser's native prompt where the platform allows.
5. All visible text in the view is Finnish. Reward is labelled "Palkkio (alv 0%)", customer total "Yhteensä (sis. alv)", and the providers block carries one explanatory line stating that the reward and the customer price use different VAT bases (reward excludes VAT, customer price includes it). Labels only; no schema or amount change.

## Rationale
Five independent save buttons let the manager save one field and silently lose the others, and the prod sample in `orders-manager-service-price-auto-compute` already shows reward > price rows from manual entry. The reward is VAT 0% while the customer price is VAT-inclusive, so the two numbers are not directly comparable without a label; rejecting reward > price compares the raw stored amounts (the strictest plausible check) and needs no VAT math.

## Implementation
- Stored values stay in cents (`Price.cents`); only the field display/edit layer changes to euros.
- Validation runs on the block's save action (and may also show the error live); the save action returns without calling the update events when invalid.
- Unsaved count = fields whose current value differs from the last saved/loaded value.
- Does not change `orders-manager-service-price-auto-compute` (service editor auto-fill) nor `orders-provider-reward-visibility`.

## Verification
Entering a provider reward higher than the customer price and pressing the block save shows a Finnish inline error, performs no update, and shows no confirmation dialog; editing two fields shows "2" unsaved; navigating away with unsaved edits shows a leave/stay prompt; the view contains no English strings and no per-field save button.
