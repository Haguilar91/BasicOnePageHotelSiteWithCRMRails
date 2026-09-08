# Verdict: REDESIGN

**Total score: 16/30**, below the REFINE threshold of 20. No load-bearing principle
(#2 useful, #4 understandable, #6 honest) scored 0 — all three scored a full 3/3 — so
this is not a case of the product failing at its core job. The redesign this verdict
calls for is scoped to the **presentation layer** (image/asset pipeline, motion, and
color-pairing discipline), not the information architecture, copy voice, or booking
flow, all of which are already sound and should be preserved.

In one sentence: the site knows what it's for and says it plainly, but ships nearly
48MB of unoptimized images and two never-ending decorative animations — one of which
is actively broken (a mismatched gradient color visibly pulses through every primary
button, forever) — and that combination is enough independently-stacking damage
(#3, #5, #7, #8, #9, #10 all scored ≤2) to clear the REDESIGN bar on total score alone.

## Top 5 highest-leverage moves

1. **#9 environmentally friendly (0/3) — fix the image pipeline.**
   Add ActiveStorage variants (`resize_to_limit`) for every room/offer/activity/gallery
   photo instead of serving originals directly. Evidence: 45.48MB of the page's 47.86MB
   is unoptimized images, one single file at 8.1MB (`01-evidence.md §4`;
   `url_for(photo)` used with no `.variant()` anywhere in `app/views/home/index.html.erb`).
   This is the single highest-leverage fix on the whole scorecard — it alone would move
   #9 from 0 toward a 2 or 3.

2. **#3 aesthetic / #8 thorough — repair the `.btn-gold` gradient.**
   Update `Theme#accent_soft` to an actual tint of the current `accent` (`#7C2D12`)
   instead of the leftover `#DACFCD` from before the accent was changed. Evidence:
   live-measured gradient is `rgb(124,45,18) → rgb(218,207,205) → rgb(124,45,18)` —
   terracotta fading through an unrelated dusty pink — visible on 5 buttons site-wide,
   captured directly in `audit_rooms.png` / `audit_contact.png` (`01-evidence.md §2`).

3. **#5 unobtrusive / #9 environmentally friendly — gate or remove the idle animations.**
   Wrap the `shine` and `floating` `@keyframes` (`index.html.erb:109`, `:119`) in
   `@media (prefers-reduced-motion: no-preference)`, and reconsider whether infinite
   looping is needed at all versus a one-shot animation on load/hover. Evidence: 7
   elements animate forever with zero motion-preference gate (`01-evidence.md §2, §4`).

4. **#8 thorough — validate accent against the hero photo, not just flat theme surfaces.**
   The hero eyebrow text (`text-[var(--color-accent)]`, `index.html.erb:271`) sits on a
   photograph, which the contrast validation added to `Theme` this session cannot see —
   it only checks accent against `bg_primary/secondary/tertiary`. Evidence: the current
   terracotta accent visibly blends into a red-brick hero photo (`audit_hero.png`).
   Either give hero text a fixed high-contrast treatment (shadow/scrim) independent of
   the admin-editable accent, or document that accent should be re-checked by eye
   whenever the hero photo changes.

5. **#10 as little design as possible — clear out dead weight.**
   Delete `app/views/layouts/application.html.erb.orig` (orphaned backup, not part of
   any render path) and either remove `Theme#text_muted`/its Avo field or repurpose it
   now that this session's own fix made its stored value unused
   (`01-evidence.md §1`).

## What to preserve (do not touch in the coming plan)

- Information architecture and section order (#2, #4 both scored 3/3) — nav labels,
  section grouping, and the 6-entry-point booking pattern are working as intended.
- The live copy voice — factual, unembellished, already better than the codebase's own
  fallback strings (#6 scored 3/3, `01-evidence.md §3`).
- The 5-color admin-editable palette and its auto-computed contrast system built
  earlier this session — the *system* is sound; only one derived pairing
  (`accent_soft`) and one edge case (photo backgrounds) need attention.
