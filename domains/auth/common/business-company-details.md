---
id: auth-common-business-company-details
domain: auth/common
title: Business company details are written only by the updateBusinessCompany callable
status: active
applies_to: [web]
tags: [auth, business-customer, company, billing, callable, firestore-rules]
supersedes: []
created: 2026-10-18
updated: 2026-10-18
---
## Rule
The Business portal Company details screen MUST persist company data only through the callable
`updateBusinessCompany`, and the primary contact only through the existing `updateProfile`.

- `updateBusinessCompany` requires an authenticated caller whose `role` claim contains
  `business-customer`; any other caller is rejected (`permission-denied`, unauthenticated ->
  `unauthenticated`).
- It writes only these keys to `business_customers/{uid}` (merge): `companyName` (required, never
  empty), `businessId` (Y-tunnus `1234567-8`), `vatNumber` (`FI12345678`), `streetAddress`,
  `postCode`, `city`, `billingEmail`. Unknown keys are rejected by the request schema. An empty
  string removes an optional field.
- Clients MUST NOT write `business_customers` directly: Firestore rules keep it read-only for the
  owner (and readable by services manager), with no client write rule.
- The primary contact (name, phone, email) is `customers/{uid}.contact`, saved with the full
  contact object through `updateProfile`.

## Rationale
Only the owner account may change billing identity of a company; a callable keeps validation
(business ID, VAT, email) server-side and leaves the rules unchanged.

## Implementation
- Request schema `update-business-company-request.schema.json`; handler
  `cf/functions/src/updateBusinessCompany.ts`; Dart `Backend.updateBusinessCompany`.
- The screen streams `business_customers/{uid}` and shows only fields that exist in this rule.

## Verification
Given a `customer,business-customer` caller sending `{vatNumber: 'FI12345678'}`, the field is
stored; sending `{vatNumber: ''}` removes it; `{businessId: '123'}` fails with
`invalid-argument`. A `customer`-only caller gets `permission-denied`. A client SDK write to
`business_customers/{uid}` is denied.
