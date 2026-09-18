---
id: company-team-list-shows-pending-invitations
domain: company
title: Company team list MUST show pending worker invitations alongside active workers
status: active
applies_to: [all]
tags: [company, worker, invite, team, panel]
supersedes: []
created: 2026-08-04
updated: 2026-08-04
---
## Rule
The company team list (`TeamPartial`, panel "Team" tab) currently only renders workers
already associated with the company (`providers` docs where `company == companyId`). It
MUST also render pending invitations — rows for `workers_invitations` docs matching the
company that have not yet been accepted (i.e. the doc still exists; `joinCompanyAsWorker`
deletes it on acceptance, so existence == pending) — in the same list, visually
distinguished with a "Pending" status marker in place of the review/availability columns.

## Rationale
A manager inviting several workers has no visibility into who has been invited but hasn't
joined yet — the invitation just silently waits in Firestore until accepted or forgotten.
Surfacing pending invitations in the same list workers appear in closes that gap with the
existing data (no new backend calls needed to invite).

## Implementation
- Read-only display only. No new callable, no cancel/resend action in this pass.
- New repo: `CompanyRepos`/`Repos` gains a read of `workers_invitations` scoped
  `where('companyId', isEqualTo: company)`, exposed as
  `RemoteDataBloc<List<CompanyWorkerInvitationViewModel>>` (new lightweight entity:
  `email`, `services`, doc id — no `ServiceProvider` fields since the worker hasn't joined).
- `TeamBloc` gains a second list (`pendingInvitations`) merged into a single row model that
  the view renders as `{worker}` rows first, `{pendingInvitation}` rows after, distinguished
  by a `status` sealed indicator: `active` vs `pending`.
- `UsersListTable`/`_UserRow` (desktop + mobile) render pending rows with: avatar
  placeholder, `workerEmail` in place of name, no role/services chips beyond the invited
  `services` list (if present), no availability bar, no review section, and a "Pending"
  badge in the trailing column instead of the details dropdown.
- No schema change: `workers_invitations` docs already match the existing
  `CompanyWorkerInvitation` schema (`companyId`, `workerEmail`, `services?`, `dailyPlan?`).

## Verification
Opening the company Team tab for a company with N joined workers and M pending invitations
shows N+M rows total: the N worker rows unchanged, plus M rows reading the invited email
with a "Pending" indicator, sourced from `workers_invitations` docs for that company.
