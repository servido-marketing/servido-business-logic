---
id: website-gallery-supports-video-alongside-photos
domain: website
title: Service landing page "gallery" section MAY mix videos with photos
status: active
applies_to: [web]
tags: [website, service-landing, gallery, media, video, photo, cms]
supersedes: []
created: 2026-08-11
updated: 2026-08-11
---
## Rule
A service landing page's `gallery` section (`ServiceLandingContent.images.gallery`) MUST
support video items in the same grid as photo items — not just photos. A gallery item is
EITHER a photo or a video; videos MUST be visibly distinguishable (a play affordance) and
MUST play on click, matching the existing hero-video click-to-play interaction pattern
already used by the `video` section on the same page. Video files served in this section
MUST be compressed before landing in the repo (web-delivery bitrate/resolution, not raw
export/phone-camera output) — this is a content/authoring guard, not a runtime transcode.

## Rationale
- Gallery is curated per-service marketing content (`src/content/service-landing/*.json`),
  same authoring surface as the existing `before`/`after`/`video` slots — video belongs
  there as just another asset kind, no new authoring surface needed.
- Reuses the page's existing click-to-play pattern (`data-video` attribute → dynamically
  created `<video controls autoplay>`) instead of inventing a second video UI.
- Uncompressed phone-export video (often 10-30 MB/clip) shipped directly into
  `public/images/service-landing/` would blow up page weight; compressing at authoring
  time (H.264/AAC mp4, capped bitrate/resolution) keeps the marketing page fast.
- Explicitly separate from `cms-service-video-uploads` (manager-panel `supplementaryVideos`
  on a live `Service` entity) — that card's videos are NOT wired to any customer surface yet.
  This card is about the hand-authored marketing landing-page gallery content pipeline,
  a different data path (static JSON content, not Firestore).

## Implementation
- **Content shape.** `ServiceLandingContent.images.gallery` (currently `string[]` of photo
  URLs, built in `serviceLandingJson.ts` from `images.gallery1..gallery6`) becomes an array
  of `{ type: 'photo' | 'video'; src: string; poster?: string }` items instead of bare
  strings. `serviceLandingJson.ts` keeps reading `gallery1..gallery6` from the JSON but each
  slot's value may now be an object `{ "type": "video", "src": "...", "poster": "..." }` as
  well as a bare photo path string (bare string == `type: 'photo'`, backward compatible).
- **Rendering.** `ServiceLandingPage.astro`'s GALLERY section (`gallery.map`) renders a
  photo tile as today (`<Image>`), and a video tile as a poster image + play button reusing
  the same `data-video` click-to-play wiring already implemented for the `video` section
  (same `<script>` block, extend its `[data-video]` selector to also match gallery tiles).
- **Compression guard.** Any video file added to `public/videos/service-landing/` (new dir,
  parallel to `public/images/service-landing/`) MUST be re-encoded via ffmpeg
  (`-c:v libx264 -crf 26 -preset veryslow -vf scale=-2:720 -c:a aac -b:a 96k -movflags
  +faststart`) before being committed — never commit an unprocessed source export.
- **Poster frames.** Each gallery video item SHOULD have a `poster` (extracted first-frame
  or representative still, webp) so the tile doesn't show a blank/black box before play.

## Verification
Proof shows: (a) a service landing page whose `gallery` content includes at least one
`type: 'video'` item renders a play-affordance tile in the gallery grid; (b) clicking that
tile plays the video inline via the existing click-to-play pattern; (c) a plain photo
gallery item (bare string, pre-existing content files) still renders unchanged
(regression-safe); (d) any committed gallery video file is <= ~3 MB and encoded H.264/AAC
mp4 with `+faststart` (compression guard honored, not raw phone-export footage).
