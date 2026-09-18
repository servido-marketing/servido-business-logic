---
id: cms-service-video-uploads
domain: cms
title: Manager can attach videos to a service, alongside existing photos
status: active
applies_to: [web]
tags: [cms, services, panel, media, video, photo, manager, upload, supplementaryVideos]
supersedes: []
created: 2026-07-17
updated: 2026-07-17
---
## Rule
A services manager MAY upload one or more videos to a service in the manager panel,
the same way photos can already be added to a service's supplementary gallery today.
Videos are additive media alongside `supplementaryPhotos` — they do NOT replace photos,
are NOT limited in count beyond normal storage/size guards, and are stored per-service
(not per-local-service in this first slice — see Scope). Only a services manager may
add or remove a service video; the write MUST go through dedicated server-side
callables, never a direct Firestore write from the panel.

Customer-facing display of these videos (marketplace app, website service page, local
service page) is explicitly OUT OF SCOPE for this rule/slice — the manager can only
upload/manage them in the panel for now; a later card will define where and how they
render to customers.

## Rationale
- Managers already curate a photo gallery per service (`supplementaryPhotos`); video is
  the natural next media type for the same curation surface, and reusing the existing
  gallery-editing UX/pattern (add / delete) minimizes new surface area.
- Splitting "manager can upload" from "customer sees it" lets the panel-only capability
  ship now without having to also design/implement customer-facing video players across
  three apps in the same slice.

## Implementation
- **Model.** Add `supplementaryVideos: Video[]` to `ServiceProperties`
  (`docs/schemas/service-properties.schema.json`), parallel to the existing
  `supplementaryPhotos: Photo[]`. Reuses the existing `video.schema.json` (path, frame
  thumbnail as a `Photo`, bytes) — no new media schema needed.
- **Commands.** Two new manager-guarded callables mirroring the existing photo pair:
  - `addServiceVideo(serviceId, video)` — arrayUnion onto
    `properties.supplementaryVideos`, guarded by `guard.manage`, mirrors
    `addServicePhoto`.
  - `deleteServiceVideo(serviceId, videoPath)` — transactional filter-by-path removal
    from `properties.supplementaryVideos`, mirrors `deleteServicePhoto`.
  Local-service video upload is NOT part of this slice (local services keep
  photo-only supplementary media for now); only plain `services` get video support.
- **Panel UI.** The existing service-media-editing section (wherever
  `supplementaryPhotos` is edited/uploaded in the manager panel) gains a video
  upload control alongside the photo one, using the same upload pipeline (storage
  bucket + thumbnail/frame generation) already used for photos, adapted for video
  (frame extraction reuses the `Video.frame` Photo-shaped thumbnail already in the
  schema).
- **No customer surface changes in this slice** — do not wire `supplementaryVideos`
  into any customer-facing rendering (website, marketplace, local-service pages).

## Verification
Proof shows: (a) a services manager can upload a video to a service in the panel and
it persists to `properties.supplementaryVideos`; (b) the manager can delete a
previously-added video by path and it's removed from that array; (c) a non-manager
caller of `addServiceVideo`/`deleteServiceVideo` is rejected; (d) existing
`supplementaryPhotos` add/delete flows are unaffected (regression-safe additive
schema change).
