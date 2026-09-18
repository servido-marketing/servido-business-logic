---
id: website-price-display-never-zero-for-min-zero-products
domain: website
title: "Price-from display must never show 0 € when a quantity/nominal product's min is 0"
status: active
applies_to: [web]
tags: [website, pricing, real-service, mainProductConfig, quantity, nominal]
supersedes: []
created: 2026-08-11
updated: 2026-08-11
---
## Rule
When deriving the displayed "price from" for a real service's `mainProductConfig` (or any
`quantity`/`nominal` product shown with a starting price), the unit COUNT used to compute the
displayed price MUST be `max(min, 1)`, never the raw `min` value. A configurable
quantity/nominal product legitimately allows `min: 0` (the customer can start at zero units and
add more), but the customer-facing price label MUST NEVER render `0 €` — that reads as "this
service is free," not "you haven't picked anything yet." The label must always show what ONE
unit of the product costs.

This does not change the actual booking default: the booking wizard's initial selection
(`defaultSelection` in `bookingConfig.ts`) still correctly starts the customer at `min` units
(including 0) — only the DISPLAYED price-from figure is floored to a 1-unit price.

## Rationale
A carpet-hand-wash service configured with `min: 0` (customer may add 0 mats and still order
the base task, or scale up) was showing `0 € 0 €*` on `/palvelut` and the real-service landing
page — a broken-looking price, not a legitimate "starts free" offer. The fix belongs in the
price DERIVATION, not in per-page display hacks, so every surface reading `mainConfigPrice`
(service list cards, real-service pages, any future consumer) is fixed once.

## Implementation
- `servido-website/src/lib/realServices.ts` → `mainConfigPrice(service)`: for `kind === 'quantity'`
  and `kind === 'nominal'`, compute `Math.max(v.min, 1) * v.unitPrice.value / 100` instead of
  `v.min * v.unitPrice.value / 100`.
- No schema change — `min: 0` remains a valid, unchanged stored value; this is purely a
  display-derivation floor.
- Does NOT touch `bookingConfig.ts`'s `defaultSelection`, which must keep defaulting the actual
  booking amount to the real `min` (including 0) — only the price LABEL is floored.

## Verification
- A `mainProductConfig` with `kind: 'quantity'|'nominal'`, `min: 0`, `unitPrice: X` renders a
  price-from label of `X` (1-unit price), never `0`.
- A `mainProductConfig` with `min: 1` (or higher) is unaffected — label still shows `min * unitPrice`.
- The booking wizard's actual starting selected amount for a `min: 0` product is still `0`
  (unaffected by this display-only fix).
