```
/make-plan Redesign the Hotel Mesón del Bosque homepage's presentation layer (image pipeline, motion, and color-pairing discipline). Current design failed a Dieter Rams audit at 16/30 with critical gaps in principles #9 (environmentally friendly, scored 0) and #3/#5/#8/#10 (aesthetic, unobtrusive, thorough, as-little-as-possible — all scored 1).

Verdict paragraph (quoted from the audit):
> The site knows what it's for and says it plainly, but ships nearly 48MB of unoptimized images and two never-ending decorative animations — one of which is actively broken (a mismatched gradient color visibly pulses through every primary button, forever) — and that combination is enough independently-stacking damage (#3, #5, #7, #8, #9, #10 all scored ≤2) to clear the REDESIGN bar on total score alone.

Why redesign and not refine: total score (16/30) is below the refine threshold of 20, driven by #9 environmentally friendly scoring 0/3 (47.86MB total page weight, 95% unoptimized images, one file alone at 8.1MB) plus four other principles at 1/3. No load-bearing principle failed — #2 useful, #4 understandable, and #6 honest all scored a full 3/3 — so this redesign is scoped to the presentation layer only, not the information architecture or copy.

Preserve from current design:
- Information architecture and section order: hero → features → habitaciones → ofertas → galería → servicios → que-hacer → contacto → reservar (app/views/home/index.html.erb, 9 sections). Scored #2/#4 at 3/3 — do not restructure.
- The 6-entry-point booking pattern (nav, mobile nav, hero, room cards, offer cards, CTA section) — reduces friction from anywhere on the page, do not consolidate down to fewer entry points.
- The live copy voice — factual, unembellished (e.g. current live hero subtitle describes parking/pricing plainly rather than using the codebase's own inflated fallback strings like "una experiencia de lujo"). Scored #6 at 3/3 — do not restyle toward more "marketing" language.
- The 5-color admin-editable theme system (bg_primary, bg_secondary, bg_tertiary, accent, accent_soft in app/models/theme.rb) and its auto-computed WCAG contrast vars (--color-text-on-*, --color-accent-NN via color-mix()) built earlier this session — the system itself is sound.

Discard:
- The unpaired `.btn-gold` gradient. Evidence: linear-gradient(135deg, accent 0%, accent_soft 50%, accent 100%) currently renders rgb(124,45,18) → rgb(218,207,205) → rgb(124,45,18) — terracotta fading through an unrelated dusty pink — on all 5 CTA buttons site-wide (app/views/home/index.html.erb:224,289,716,975), animated forever via @keyframes shine (index.html.erb:109). Caused failure on principles #3 and #8.
- Serving full-size ActiveStorage originals directly via url_for(photo) with no .variant() anywhere in the room/offer/activity/gallery photo rendering (app/views/home/index.html.erb). Caused failure on principle #9 — 45.48MB of the page's 47.86MB total weight, one file at 8.1MB.
- Unconditional infinite CSS animation with no prefers-reduced-motion gate: @keyframes shine and @keyframes floating (index.html.erb:109, :119), 7 elements animating forever at idle. Caused failure on principles #5 and #9.

Top 5 moves from the audit (verbatim):
1. #9 environmentally friendly: Add ActiveStorage variants (resize_to_limit) for every room/offer/activity/gallery photo instead of serving originals directly. Evidence: 45.48MB of 47.86MB total page weight is unoptimized images; url_for(photo) used with no .variant() anywhere in app/views/home/index.html.erb.
2. #3 aesthetic / #8 thorough: Update Theme#accent_soft to an actual tint of the current accent (#7C2D12) instead of the leftover #DACFCD from before the accent was changed. Evidence: live-measured gradient rgb(124,45,18) → rgb(218,207,205) → rgb(124,45,18), visible on 5 buttons, captured in screenshots taken against the live site.
3. #5 unobtrusive / #9 environmentally friendly: Wrap the shine and floating @keyframes (index.html.erb:109, :119) in @media (prefers-reduced-motion: no-preference), and reconsider whether infinite looping serves any purpose versus a one-shot or hover-triggered animation. Evidence: 7 elements animate forever with zero motion-preference gate.
4. #8 thorough: Validate the accent color against the hero photo, not just flat theme surfaces — the contrast validation added to Theme this session only checks accent against bg_primary/secondary/tertiary, not arbitrary photo content. Evidence: the current terracotta accent (text-[var(--color-accent)], index.html.erb:271) visibly blends into a red-brick hero photo in a live screenshot. Either give hero text a fixed high-contrast treatment (shadow/scrim) independent of the admin-editable accent, or document that accent needs a manual eyeball-check whenever the hero photo changes.
5. #10 as little design as possible: Delete app/views/layouts/application.html.erb.orig (orphaned backup, not part of any render path) and either remove Theme#text_muted / its Avo swatch field or repurpose it, since this session's own earlier fix (auto-computed muted_text_color) made its stored value functionally unused.

Redesign principles in priority order:
1. #9 Environmentally friendly — every photo on the page ships at a size appropriate to its display context, not its original upload size.
2. #3 Aesthetic — every color pairing (including animated gradients) is derived from or explicitly checked against the current admin-set palette, never left over from a prior palette.
3. #5 Unobtrusive — any looping motion respects prefers-reduced-motion and exists because it serves the content, not by default.

Deliverables for the plan:
- Image variant strategy: which ActiveStorage variant sizes to generate, for which display contexts (hero, room card, gallery thumbnail, gallery lightbox), and a migration/backfill plan for existing uploads.
- Corrected accent_soft value (or a documented formula for deriving it from accent automatically, e.g. a lighter color-mix of accent, so this can't drift out of sync again).
- prefers-reduced-motion audit covering both existing @keyframes and any new motion introduced.
- A specific fix (or documented decision) for hero-text-on-photo contrast that doesn't depend on the admin-editable accent alone.
- Cleanup list execution: the .orig file and the text_muted field/column.
- Before/after page-weight measurement to confirm the #9 fix actually lands (target: well under the rubric's 2MB "good" threshold for a marketing page, images included).

Anti-patterns to guard against (specific to REDESIGN):
- Porting the same "serve the original blob" pattern to any new photo feature.
- Keeping the infinite shine/floating animations "just gated" behind prefers-reduced-motion as a checkbox exercise, without asking whether they should exist at all.
- Treating the Preserve list as optional — the IA, copy voice, booking-entry-point pattern, and theme system must survive this pass unchanged.
- Redesigning the color palette itself (accent/bg choices) — the palette was validated and fixed earlier this session; only the *pairing discipline* (accent_soft, photo-contrast) failed, not the palette.
```
