---
id: company-worker-invitation-email
domain: company
title: Worker invitation email MUST use a branded Mailgun template and show the inviting company's name
status: active
applies_to: [all]
tags: [company, worker, invite, email, onboarding, mailgun, template]
supersedes: []
created: 2026-07-16
updated: 2026-07-16
---
## Rule
When a company invites a worker (`inviteCompanyWorkers`), the invitation email MUST be
sent as a branded Mailgun HTML template (`sendMailTemplate`), consistent with Servido's
other transactional emails, NOT the current raw plaintext `sendMail` call. The email body
MUST display the name of the inviting company so the recipient knows who is inviting them
before they accept.

## Rationale
The current implementation sends a bare-text Mailgun message (`sendMail`) with a raw join
link and no branding, and never names the inviting company — a worker receiving it has no
way to tell which company sent the invite (relevant for workers who may get invited by
multiple companies over time, or receiving an unsolicited invite from an unfamiliar one).
Every other outbound Servido transactional email already uses a designed MJML/Handlebars
template (see `customer-welcome__customer.html`, `new-job__service-provider.html`) for
consistent branding and legibility; the worker invite is the one outlier still on raw text.

## Implementation
- New Mailgun template `company-worker-invitation__worker` (account-scope v4, same visual
  shell as `customer-welcome__customer.html`: header banner, `h1` title, body paragraphs,
  CTA-style join link, signoff, footer) — content in Finnish per the `fi`-only localization
  policy, mirroring existing template copy conventions.
- Template variables (flat snake_case union, per `template-variables.md` convention):
  `company_name` (the inviting company's display name) and `join_link` (the existing
  `https://app.servido.co/invite?company=...&email=...` URL, unchanged).
- Backend (`cf/functions/src/inviteCompanyWorkers.ts`): resolve `company_name` by reading
  `providers/{companyId}` → `contact.fullName` (this is the same field
  `setupProviderProfileFiCompany` already populates from the company's registered name —
  reuse it, do not add a second company-name field). If `contact.fullName` is missing,
  fall back to a generic "Servido-yritys" label rather than failing the invite.
  Replace the `sendMail(...)` call with `sendMailTemplate({ template:
  'company-worker-invitation__worker', variables: { company_name, join_link } })`.
- No schema shape change needed: `CompanyWorkerInvitation` / `InviteCompanyWorkersRequest`
  already carry `companyId`; the company name is looked up server-side, not passed by the
  client.

## Verification
Inviting a worker sends an email through `sendMailTemplate` (not `sendMail`) using the
`company-worker-invitation__worker` template, and the rendered email body contains the
inviting company's `contact.fullName` value (or the fallback label when unset) somewhere
in the visible copy.
