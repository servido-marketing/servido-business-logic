---
id: orders-quantity-product-custom-unit
domain: orders
title: Quantity-type products/addons must allow a manager-defined unit name
status: active                  # active | superseded | deprecated
applies_to: [web, mobile, all]  # which surfaces this binds; use [all] if universal
tags: [products, addons, pricing, quantity, unit]
supersedes: []
created: 2026-09-22
updated: 2026-09-22
---
## Rule
A `quantity`-kind product/addon config (main product or attached addon) MUST let the manager
set a custom unit label (localized text). If the manager leaves it blank, the client MUST fall
back to the existing default unit label (`"kpl"` in Finnish / `"pc"` in English) — never blank
text or a raw `undefined`.

## Rationale
Quantity products always rendered a hardcoded "kpl" unit regardless of what the product actually
counts (e.g. "session", "window", "bag"). Decimal/nominal products already carry a manager-set
`unit` (`LocalizedText`); quantity products should have the same capability instead of being
permanently locked to "kpl"/"pc".

## Implementation
- Add an OPTIONAL `unit: LocalizedText?` field to the quantity product/addon value shape,
  mirroring `NominalAdditionalProductValue.unit` (which is required there; here it stays
  optional to preserve the default-fallback behavior above).
- `docs/schemas/quantity-product-option-value.schema.json`: add optional `unit` property,
  `$ref` to the localized-text schema used elsewhere (see how
  `nominal-product-option-value.schema.json`, or equivalent, references it), NOT added to
  `required`.
- Backend (`cf/functions/src/transactionSchemas`/mapping): thread `unit` through unchanged,
  no server-side default substitution — defaulting is a display concern.
- Flutter (`model`): add `final LocalizedText? unit;` to
  `QuantityAdditionalProductValue` (packages/model/lib/src/entities/service_additional_product.dart).
- Flutter (`backend` mapping): thread `unit` in both directions in
  `packages/backend/lib/src/mapping.dart` and the transaction type in
  `packages/backend/lib/src/transaction_types/transaction_types.dart`.
- Manager form (`web_ui` custom_service_form / product_creator_bloc, plus
  additional_products_section view): expose a unit text input for the `quantity` type option
  the same way it already exists for `decimal`, but NOT required — empty is valid and means
  "use default".
- Display (`ui` package: quantity_selector.dart, display.dart, service_cell.dart, and website
  equivalents `RealServicePicker.tsx` / `[id].astro` where a quantity-kind product resolves its
  unit label): resolve unit as `product.unit?.isNotEmpty == true ? product.unit! :
  defaultUnitLabel(locale)` where `defaultUnitLabel` is the existing "kpl"/"pc" fallback string
  (already localized via `l10n.unit` on Flutter / the `lang === 'fi' ? 'kpl' : 'pc'` ternary on
  website).
- Website manager UI (if quantity addons/products are editable on servido-website — verify
  before assuming; if manager-side quantity editing is Flutter-only, skip the website form
  change and only fix the DISPLAY side there).

## Verification
- Manager sets a custom unit (e.g. "istunto") on a quantity product/addon → every surface that
  displays that product's per-unit price/label (Flutter quantity selector, provider task
  preview, manager service cell, website product picker if applicable) shows "istunto" instead
  of "kpl"/"pc".
- Manager leaves the unit field blank/unset → all surfaces fall back to the existing
  "kpl" (fi) / "pc" (en) default, unchanged from current behavior — no blank/undefined unit text.
