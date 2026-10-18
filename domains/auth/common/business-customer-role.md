---
id: auth-common-business-customer-role
domain: auth/common
title: Business customer is an additive role that opens the Business portal panel
status: active
applies_to: [web, mobile, all]
tags: [auth, role, business-customer, business, portal, panel, claims, landing]
supersedes: []
created: 2026-10-17
updated: 2026-10-18
---
## Rule
A company that orders services for many properties MUST be represented by the role
`business-customer` (custom claim value `business-customer`, Dart `UserRole.businessCustomer`).

- The role is ADDITIVE: every business customer ALSO holds the `customer` role and a
  `customers/{uid}` document. Claim value is a comma list, e.g. `customer,business-customer`.
  Their orders, properties (houses) and credits stay in the existing customer data.
- Business-specific data lives in `business_customers/{uid}` (`companyName`, optional
  `businessId`, `vatNumber`, `address{streetAddress,postCode,city}`, `billingEmail`, `createdAt`).
  Created together with the role; the owner edits it only through `updateBusinessCompany`
  (see `auth-common-business-company-details`).
- On web login a user holding `business-customer` MUST land in the Business portal panel, a
  sibling of the SP panel, manager, company and admin panels. Staff roles keep priority:
  admin, services-manager and provider land in their own panels first; the Business portal
  wins over the plain `customer` branch (which otherwise onboards the user as an SP).
- A plain `customer` MUST NOT see the Business portal; a business customer MUST only ever see
  their own tasks and properties.
- Every client that decodes the claim MUST accept `business-customer` and MUST NOT throw on it
  (mobile and website included).

## Rationale
Business customers are a different product surface (multi-property ordering, reporting) but the
same legal customer entity as a consumer; reusing the customer data avoids a second order
model and keeps customer-side rules (credits, cancel, reschedule, order number) intact.

## Implementation
- `createProfile` accepts `role: 'business-customer'`: sets claims `customer` (if missing) and
  `business-customer`, creates `customers/{uid}` and `business_customers/{uid}`. The existing
  `allowProvidersRegistration` gate applies (non-`customer` roles), so in prod the role is
  granted by the operator until a self-service or manager grant flow is decided.
- `user-role.schema.json` enum gains `business-customer`; regenerate transaction types.
- Firestore rules: `business_customers/{uid}` readable by its owner; services manager may read.
- Landing resolution order: servicesManager, admin, provider, businessCustomer, customer.

## Verification
Given a user with claims `customer,business-customer`, web login lands on the Business portal
(sidebar item `Dashboard` visible, no SP panel). Given a user with claim `customer` only,
web login does not show the Business portal. Decoding claim `customer,business-customer`
yields both roles with no error.
