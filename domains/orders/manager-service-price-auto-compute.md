---
id: orders-manager-service-price-auto-compute
domain: orders
title: Manager price input auto-computes provider reward and deducted price
status: active
applies_to: [web]
tags: [pricing, manager-panel, service-form, deduction, providerReward]
supersedes: []
created: 2026-09-23
updated: 2026-09-23
---
## Rule
When a manager enters/changes the base `price` on a service (main service configuration,
`PricingSection` in the manager service editor), the form MUST auto-fill two derived fields
that the manager can still override by hand:
- `deduction.deductedPrice` = `price * 0.60` (rounded to the nearest cent), whenever
  `deduction.isDeductable` is true. This is the Finnish household-deduction (kotitalousvähennys)
  net price shown to the customer.
- `providerReward` = `round(price * 0.85 / 1.255)` (rounded to the nearest cent) as a starting suggestion.

Auto-fill only fires when the target field is empty or still holds a value that matches the
previous auto-computed suggestion (i.e. the manager hasn't manually diverged from the
suggestion yet). Once a manager types a value into `providerReward` or `deductedPrice` that
differs from the last auto-computed suggestion, further edits to `price` MUST NOT overwrite
that manual value — the auto-compute only pre-fills, it never fights a human edit.

This rule applies to the main service price ONLY (`PricingSection`), not per-work-item or
per-additional-product pricing, which managers already set independently and which have no
single-ratio pattern in production data.

## Rationale
Prod Firestore sample (n=27 services with both `price` and `providerReward` set,
2026-09-23) initially showed no consistent providerReward ratio. Operator subsequently
supplied the actual business formula directly (2026-09-23 call), which supersedes that
sample-derived guess:
- `deductedPrice / price` = 0.60 — confirmed both by the prod sample (tight 0.56–0.60,
  mostly exactly 0.600 across all 14 deductable samples) and by the operator: "40% cut →
  60% shown as deducted price", i.e. `deducted_price = price * 0.60`.
- `providerReward = round(price * 0.85 / 1.255)` — operator-supplied formula (0.85 =
  post-fee share, 1.255 = VAT-related divisor). Verified against the operator's worked
  example: price 479 → `479 * 0.85 / 1.255 = 324.42` → rounds to 324, matching the call.

Today the manager panel presents `price`, `providerReward`, and `deduction` as three
independent blank text fields (see `pricing_section.dart`) with zero cross-field
computation — every service creation requires the manager to manually type and mentally
compute all three, which is repetitive and error-prone (the sampled data shows outlier
rows like reward > price, likely mistakes from manual entry).

## Implementation
- Auto-compute lives in the manager service editor's form bloc that owns `price`,
  `providerReward`, `deduction` (`ServiceFormBloc` and its `pricing`-adjacent sub-blocs) —
  listen for `price` value changes and push a computed suggestion into `providerReward`'s
  and `deduction.deductedPrice`'s underlying value stream, ONLY when that target field is
  still at its last-known auto-computed value (track the last suggestion so we can tell
  "matches old suggestion, safe to overwrite" apart from "manager typed something else,
  hands off").
- Rounding: round to nearest cent (integer `Price.value` in minor units, i.e.
  `round(price.value * 0.60)` for deducted price, `round(price.value * 0.85 / 1.255)`
  for provider reward).
- `deductedPrice` suggestion only applies while `deduction.isDeductable` is true; if
  deduction is off, don't populate/overwrite `deductedPrice`.
- No backend/schema change — `price`, `providerReward`, `deduction.deductedPrice` are
  already-existing fields (see `docs/schemas/deduction.schema.json`,
  `mainServiceConfiguration.providerReward` in prod data); this is client-side form
  UX only. Docs note added to `backend-design.md` documenting the auto-fill convention
  so future service-form work doesn't reintroduce three independently-blank fields.

## Verification
- Entering a `price` into an empty new-service form auto-fills `providerReward` to
  `round(price * 0.85 / 1.255)` and `deductedPrice` to `round(price * 0.60)` (when
  deductable). Example: price 479 → deductedPrice 287.40, providerReward 324.
- Manually overwriting `providerReward` (or `deductedPrice`) to a value different from the
  current auto-computed suggestion, then changing `price` again, does NOT overwrite the
  manager's manual value.
- Toggling `deduction.isDeductable` off stops `deductedPrice` auto-fill; toggling it back on
  while `price` is still set re-populates `deductedPrice` from the current price (if the
  field is still at/derived-from the last suggestion, not manually diverged).
