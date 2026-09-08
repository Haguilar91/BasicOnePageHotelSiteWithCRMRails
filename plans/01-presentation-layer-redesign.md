# Plan: Homepage presentation-layer redesign

Source: Dieter Rams audit (`DESIGN-IS-2026-09-07/`), verdict REDESIGN at 16/30.
Scope: **presentation layer only** — image pipeline, motion, color-pairing discipline.
Explicitly NOT in scope: information architecture, copy voice, the booking-modal UX,
or the palette *choice* (bg/accent hex values) — all of those scored 3/3 and must
survive this plan unchanged. The hero-eyebrow-on-photo legibility item from the
original audit is already fixed (a `bg-black/45` pill chip around the "BIENVENIDOS A
QUERÉTARO" text, `app/views/home/index.html.erb:271`) — do not touch it again.

Each phase below is self-contained and can be executed in a fresh session with no
memory of this one — every fact needed is inlined, not referenced.

---

## Phase 0: Documentation Discovery (findings, already verified this session)

**Sources consulted:** `Gemfile`/`Gemfile.lock`, `app/views/pwa/manifest.json.erb`,
`app/views/home/index.html.erb`, `app/models/theme.rb`, `app/avo/resources/theme.rb`,
`db/seeds.rb`, `app/assets/javascripts/room_gallery.js`, live shell checks
(`which vips`).

**Allowed APIs / confirmed patterns:**

- **ActiveStorage variants are already used in this exact codebase** — copy this
  pattern, don't invent a new one:
  ```erb
  <%# app/views/pwa/manifest.json.erb:8 — existing, working pattern %>
  "<%= url_for(page_content.app_icon, size: '512x512') %>"
  ```
  `url_for(attachment, size: 'WxH')` is Rails' built-in shorthand — it creates (and
  caches) a `resize_to_limit`-equivalent variant and returns its URL. No `.variant()`
  call, no `.processed`, no extra config needed.
- **Variant processor is already installed and working:** `Gemfile` has
  `gem "image_processing", "~> 1.2"` (resolved to `1.14.0` with `ruby-vips 2.3.0` in
  `Gemfile.lock`), and `vips`/`vipsthumbnail` binaries are present on the box
  (confirmed via `which vips vipsthumbnail`). Rails 7+ defaults
  `config.active_storage.variant_processor` to `:vips` and nothing in `config/`
  overrides it — no processor config needed, it already works.
- **`color-mix()` is already an established pattern in this exact file** — not just
  from earlier this session's work, but pre-existing:
  ```css
  /* app/views/home/index.html.erb:162 (.mobile-bottom-nav), already shipping */
  border-top: 1px solid color-mix(in srgb, var(--color-accent) 22%, transparent);
  ```
  Copy this exact syntax for the `accent_soft` fix in Phase 2.
- **Both photo-gallery lightboxes read the clicked thumbnail's own rendered `src`**,
  they do not fetch a separate full-resolution URL:
  - Room gallery: `app/views/home/index.html.erb:333`,
    `room_photo_urls = room.gallery_photos.map { |p| url_for(p) }` — this single array
    feeds both the inline card carousel (`h-64`, i.e. ~256px tall) AND is passed via
    `data-photos` JSON to the JS lightbox (`room_gallery.js:103`,
    `JSON.parse(gallery.getAttribute('data-photos'))`).
  - Hotel gallery: `app/views/home/index.html.erb:1098`,
    `const photos = thumbs.map(img => ({ src: img.src, alt: img.alt }))` — the lightbox
    literally reads the thumbnail `<img>`'s own `.src`.
  - **Implication:** one variant size must serve both the grid thumbnail AND the
    lightbox zoom for each of these two galleries. There is no separate "full size"
    slot to preserve — do not add one, that would be inventing structure that doesn't
    exist. Pick one size generous enough for the lightbox (which renders up to
    `max-h-[75vh]` inside a `max-w-5xl`/`max-w-lg` container per
    `index.html.erb:849, 909` roughly) and reuse it for the grid too.

**Anti-patterns to avoid:**
- Do NOT use `.variant(resize_to_limit: [w, h]).processed` — that's the eager/explicit
  form meant for background pre-generation; the `size:` shorthand already used in this
  codebase is lazy and sufficient for on-demand web serving.
- Do NOT add a `config.active_storage.variant_processor` line — it's already correct
  by default, adding one would just be dead config claiming to fix something that
  isn't broken.
- Do NOT introduce a second "full resolution" URL slot for the two lightboxes — the
  existing JS reads the thumbnail's own src; respect that, don't restructure it.

---

## Phase 1: Image variants (fixes #9, the highest-leverage item — 45.48MB → target well under a few MB)

**What to implement** — copy the `url_for(attachment, size: 'WxH')` pattern from
`app/views/pwa/manifest.json.erb:8` into every photo-rendering spot in
`app/views/home/index.html.erb`:

1. **Hero background** (`index.html.erb:266`):
   ```erb
   <% hero_bg_url = (@hero_image&.image&.attached?) ? url_for(@hero_image.image, size: '1920x1080') : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1920&q=80' %>
   ```
   (This is the 8.1MB file from the audit — highest single-item win.)

2. **Room gallery / lightbox** (`index.html.erb:333`):
   ```erb
   <% room_photo_urls = room.gallery_photos.map { |p| url_for(p, size: '1400x1400') }.presence || [...] %>
   ```
   (One size serves both the card carousel and the lightbox — see Phase 0 finding.)

3. **Offer card photo** (`index.html.erb:427`, wherever `offer_photo` is assigned —
   grep `offer_photo =` above line 427 to find the assignment and apply `size:` there
   instead of at the `url_for` call site, so both the `<img src>` and any `alt`/other
   uses stay in sync): target `size: '900x700'` (offer cards render at roughly this
   aspect ratio; adjust to whatever the card's actual CSS box is if it differs).

4. **Hotel gallery grid / lightbox** (`index.html.erb:506`, feeding into the
   `thumbs.map(img => img.src)` lightbox read at `:1098`): `size: '1200x1200'`.

5. **Activity card photo** (`index.html.erb:587`): `size: '1200x800'`.

Adjust exact target dimensions to whatever each element's actual rendered CSS box is
(check the surrounding `class="..."` for width/aspect hints) — the point is "sized for
where it's displayed," not a specific number; the numbers above are reasonable
starting points based on the classes seen in this file as of this session.

**Documentation references:** `app/views/pwa/manifest.json.erb:8` (the pattern to
copy), Phase 0 findings above (why no extra config is needed).

**Verification checklist:**
- `grep -n "url_for(" app/views/home/index.html.erb | grep -v "size:"` — every photo
  `url_for` call should now carry a `size:` argument (id/logo/favicon lookups that
  aren't user-uploaded room/gallery/activity photos are fine to leave as-is — check
  each match by hand, don't blanket-replace).
- Load the homepage in a browser (or curl + Puppeteer as used earlier this session)
  and re-measure total page weight and largest single image — target: comfortably
  under a few MB total, no single image over ~500KB.
- Visually confirm no photo looks pixelated/blurry at its displayed size — if one
  does, its target dimensions were set too small; increase and re-check.
- Run `bin/rails test` — no test in this repo asserts on image byte size, so this
  should stay green; if anything fails, it's unrelated to this phase and needs
  separate investigation, not silencing.

**Anti-pattern guards:**
- Don't touch `manifest.json.erb`'s existing `size:` calls — they're already correct,
  this phase is about the homepage view only.
- Don't add `.variant()`/`.processed` anywhere — stick to the `size:` shorthand for
  consistency with the one existing precedent in this codebase.

---

## Phase 2: Fix the `accent_soft` gradient mismatch (fixes #3, #8)

**What to implement:** stop reading the admin-set `theme.accent_soft` value for the
CSS variable that feeds the `.btn-gold` / `.gradient-text` gradients, and derive it
from `accent` instead, using the `color-mix()` syntax already live elsewhere in this
same file.

In `app/views/layouts/application.html.erb`, find:
```erb
--color-accent-soft: <%= theme.accent_soft %>;
```
Replace with:
```erb
--color-accent-soft: color-mix(in srgb, var(--color-accent) 55%, white);
```
(55% is a starting point — tune by eye once applied; it should read as a visibly
lighter tint of the *same* hue as accent, not a different color family. For the
current live accent `#7C2D12`, this produces a warm light terracotta/peach, not the
unrelated dusty pink `#DACFCD` that's there today.)

This single change fixes **both** gradient consumers at once — confirmed both read
the same `--color-accent-soft` var:
- `.btn-gold` (`index.html.erb:104`)
- `.gradient-text` (`index.html.erb:173`)

**Follow-up (same spirit as this session's earlier `text_muted` fix — optional but
recommended for consistency):** the Avo `accent_soft` swatch field
(`app/avo/resources/theme.rb:25`) becomes vestigial once this ships, the same way
`text_muted`'s field did earlier this session. Either relabel its help text to note
it's no longer used (copy the exact pattern from `theme.rb:26`'s `text_muted` help
text: `"Texto atenuado (sin uso)"` / updated help string), or remove the field — your
call, but don't leave it silently doing nothing without a note, since that's exactly
the confusion this whole redesign traces back to.

**Documentation references:** `app/views/home/index.html.erb:162` (existing
`color-mix()` precedent in this file), `app/models/theme.rb` (the `Theme` model's own
`color-mix()`-based `text_on_*` vars added earlier this session, same technique).

**Verification checklist:**
- Reload any page and run in the browser console:
  `getComputedStyle(document.querySelector('.btn-gold')).backgroundImage` — confirm
  it's a gradient between the current accent and a lighter tint of *that same* color,
  not `#DACFCD` or any other leftover value.
- Visually watch a `.btn-gold` button for one full 3-second animation cycle — it
  should read as a single warm color breathing lighter/darker, not visibly changing
  hue.
- `bin/rails test` stays green (no test asserts on `accent_soft`'s raw value, so this
  is a style-only change).

**Anti-pattern guards:**
- Don't change `theme.accent` or any `bg_primary/secondary/tertiary` value — the
  palette itself already passed audit, only this one derived pairing was wrong.
- Don't add a new Ruby method on `Theme` for this — it's a pure CSS derivation with no
  need for server-side computation, unlike `muted_text_color` (which needed Ruby
  because it branches on light-vs-dark). Keep it simple: one `color-mix()` line in the
  layout, done.

---

## Phase 3: Gate the idle animations behind `prefers-reduced-motion` (fixes #5, contributes to #9)

**What to implement:** in `app/views/home/index.html.erb`, the animation declarations
live at:
```css
/* :106 */
.btn-gold { ... animation: shine 3s ease infinite; }
/* :119 */
.floating { animation: floating 3s ease-in-out infinite; }
```
Wrap the *animation-triggering* rules (not the `@keyframes` definitions themselves,
which are harmless if unused) in a media query, e.g.:
```css
@media (prefers-reduced-motion: no-preference) {
  .btn-gold { animation: shine 3s ease infinite; }
  .floating { animation: floating 3s ease-in-out infinite; }
}
```
This means `.btn-gold` and `.floating` need their non-animation properties (the
gradient/background itself for `.btn-gold`) to stay OUTSIDE the media query — only
the `animation:` line moves in. Split `.btn-gold`'s existing rule accordingly rather
than duplicating the whole block.

**Also reconsider, don't just gate:** the audit explicitly calls out asking whether
infinite looping serves the content at all, not just adding the media query as a
checkbox. Options worth considering (pick one, or bring back to the user if genuinely
unsure — this is a judgment call the plan shouldn't force):
- Keep looping, but only gated (minimum viable fix).
- Change to a single one-shot animation on scroll-into-view (reuse the existing
  `.fade-in`/`IntersectionObserver` pattern already in this file, `index.html.erb`
  search `fade-in` for the existing observer setup) instead of infinite.
- Trigger `shine` only on `:hover`/`:focus` instead of automatically — turns
  decoration into feedback, which is a stronger fit for principle #5.

**Verification checklist:**
- In a browser with OS-level "reduce motion" enabled (Chrome DevTools → Rendering tab
  → "Emulate CSS media feature prefers-reduced-motion: reduce"), confirm no element
  animates.
- With reduced-motion off (default), confirm the chosen behavior (still-looping,
  scroll-triggered, or hover-triggered) matches whatever this phase decided.
- `bin/rails test` stays green.

**Anti-pattern guards:**
- Don't delete the `@keyframes` blocks even if you change the trigger mechanism to
  hover — keep them defined once, referenced from wherever they're actually used.
- Don't add a JS-based motion check (`window.matchMedia('(prefers-reduced-motion)')`)
  when a pure CSS media query does the job — no JS needed here.

---

## Phase 4: Cleanup (fixes #10)

**What to implement:**
1. Delete `app/views/layouts/application.html.erb.orig` — confirmed orphaned, not
   referenced by any render path (`git rm app/views/layouts/application.html.erb.orig`
   or plain `rm` + `git add -A`, whichever this repo's workflow uses).
2. `Theme#text_muted` — already relabeled "(sin uso)" in Avo earlier this session
   (`app/avo/resources/theme.rb:26`). If Phase 2's `accent_soft` follow-up applied the
   same relabel treatment, both fields are now consistently marked. Optional stretch
   goal (only if the user explicitly wants it, per the earlier conversation's decision
   to *not* drop the column without being asked): a migration to actually drop
   `text_muted` (and `accent_soft` if it goes the same route) from the `themes` table,
   updating `Theme::COLOR_ATTRIBUTES`, `db/seeds.rb`, and
   `test/models/theme_test.rb`'s `build_colors` helper accordingly. Do not do this
   silently — confirm with the user first, consistent with how this was handled
   earlier in the same session.

**Verification checklist:**
- `git status` shows the `.orig` file removed, nothing else touched.
- `bin/rails test` stays green.
- If the optional migration was done: `bin/rails db:migrate` runs clean, and
  `Theme::FALLBACK` (in `theme.rb`) still returns valid hex for every attribute in
  `COLOR_ATTRIBUTES` (there's an existing test for this:
  `test/models/theme_test.rb`, "current falls back to a built-in palette...").

**Anti-pattern guards:**
- Don't drop any DB column without explicit user confirmation in that session — this
  mirrors a decision already made once this same day about `text_muted`.

---

## Final Phase: Verification

1. **Re-run the page-weight measurement** the same way the audit did (Puppeteer,
   `networkidle0`, sum `content-length` per resource type) against the local dev
   server with Phase 1's changes applied. Compare against the audit's baseline:
   `47.86MB total / 45.48MB images / 132 requests / 7,366ms to network-idle`. Record
   the new numbers in the phase's own notes — this is the concrete proof #9 improved.
2. **Re-check the `.btn-gold` gradient** per Phase 2's verification step — confirm by
   eye and by `getComputedStyle` that it's now a coherent single-hue gradient.
3. **Re-check motion** per Phase 3's verification step.
4. `git status` — confirm only the intended files changed (no accidental edits to
   `db/seeds.rb`'s other three themes, `Theme::FALLBACK`, or anything in the Preserve
   list from the audit).
5. `bin/rails test` — full suite green.
6. Grep for anti-patterns explicitly: `grep -n "\.variant(" app/views/home/index.html.erb`
   should return nothing (Phase 1 anti-pattern guard); `grep -n "accent_soft" app/views/layouts/application.html.erb`
   should return nothing (Phase 2 replaced it with the `color-mix()` line, no more direct
   read of `theme.accent_soft` in that file).
7. Confirm nothing in the "Preserve" list moved: the 9-section IA, the 6
   booking-entry-points, the live copy strings, and the 5-color admin theme system
   (`bg_primary/secondary/tertiary/accent` — NOT `accent_soft`'s raw value, which
   Phase 2 intentionally stopped using) should all be untouched by `git diff`.
