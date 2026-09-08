# Evidence

Gathered directly (grep/read against the repo, plus a live Puppeteer/Chromium pass
against `https://hotelmeson.hectoraguilar.dev/`) rather than via cold subagents, since
this session already holds full working context on this codebase. Every finding below
is cited to a file:line or a measured value — no unsourced impressions.

## 1. Structural Evidence

- **Interactive elements** on the homepage: 27 `<button>`, 27 `<a href>`, 9 form
  inputs/selects. (`grep -c` on `app/views/home/index.html.erb`)
- **File size:** 1,160 lines, one view, no partials — confirmed via `wc -l`.
- **Repeated pattern:** the "open booking modal" affordance (`data-book-modal-open`)
  appears **6 times** verbatim across the page: desktop nav (`:224`), mobile bottom nav
  (`:254`), hero (`:293`, via the "Reservar" link), per room card (`:399`), per offer
  card (`:481`), and the CTA section's WhatsApp/Email buttons (`:729`, `:741`).
- **9 `<section>` landmarks:** inicio, (features, no id), habitaciones, ofertas,
  galeria, servicios, que-hacer, contacto, reservar (`grep -n '<section'`).
- **Dead file:** `app/views/layouts/application.html.erb.orig` — a 1,907-byte orphaned
  backup of the layout, sitting in the repo, not part of any render path
  (`ls -la app/views/layouts/*.orig`).
- **Superseded-but-still-present field:** `Theme#text_muted` — this session's own
  earlier fix made this column's value unused (superseded by
  `Theme#muted_text_color`), but the column, its Avo swatch field, and its format
  validation are all still live (`app/avo/resources/theme.rb:26`,
  `app/models/theme.rb` `COLOR_ATTRIBUTES`).

## 2. Visual Evidence (live, Chromium)

- **Spacing scale:** `{0, 1, 2, 3, 4, 6, 8, 10, 12, 16, 20}` — 11 distinct step values,
  all standard Tailwind steps, no arbitrary/odd spacing found.
- **Type scale:** `text-xs, sm, lg, xl, 2xl, 3xl, 4xl, 5xl, 7xl` plus the implicit base
  size — 9 sizes in use across one page.
- **Distinct *chosen* colors:** only 5 independent hues drive the entire palette —
  `bg_primary`, `bg_secondary`, `bg_tertiary`, `accent`, `accent_soft` (Avo-editable,
  `app/models/theme.rb`). Every other color token in the view (`--color-text-on-*`,
  `--color-accent-NN`, etc.) is *mathematically derived* from those 5 via
  `color-mix()` — confirmed via `grep -oE` across the CSS var block in
  `application.html.erb:59-86`.
- **Hardcoded escape-hatch colors (outside the theme system):** exactly one —
  `#25D366` (WhatsApp brand green). Everything else uses theme vars, apart from the
  hero's raw-photo overlay text (`text-white`, intentionally exempted earlier this
  session since it sits on a photograph, not a flat theme surface).
- **Live theme values (measured via `getComputedStyle`):**
  `bg_primary=#F2EBE8`, `bg_secondary=#E0D0CD`, `bg_tertiary=#DED3DD`,
  `accent=#7C2D12`. Contrast of accent against bg_primary: **7.95:1** — this
  confirms the accent-color fix recommended and validated earlier this session has
  since been applied to the live site.
- **New defect found in this pass — accent-vs-photo legibility:** the hero's
  "BIENVENIDOS A QUERÉTARO" eyebrow text uses `text-[var(--color-accent)]`
  (`index.html.erb:271`), which is correct against the theme's *flat* surfaces but was
  never checked against the *photograph* behind it in the hero section. In the
  captured screenshot (`audit_hero.png`) the new terracotta accent (`#7C2D12`) visibly
  blends into the red brick building in the background photo — legible in some hero
  photos, illegible in others, since it was never validated against arbitrary image
  content.
- **New defect found in this pass — mismatched gradient partner color:** every
  `.btn-gold` button (5 on this page: nav "Reservar Ahora", hero "Ver Habitaciones",
  CTA "Llamar", CTA "Enviar por Email"/booking modal — `index.html.erb:224, 289, 716,
  975`) renders a `linear-gradient(135deg, var(--color-accent) 0%,
  var(--color-accent-soft) 50%, var(--color-accent) 100%)` animated on an infinite
  3-second loop (`@keyframes shine`, `index.html.erb:109`). Measured live via
  `getComputedStyle`:
  `linear-gradient(135deg, rgb(124,45,18) 0%, rgb(218,207,205) 50%, rgb(124,45,18) 100%)`
  — i.e. terracotta → **dusty pink** → terracotta. `accent_soft` (`#DACFCD`) was never
  updated when `accent` changed to `#7C2D12` earlier this session (flagged as an
  optional follow-up at the time, not yet actioned). The result, captured directly in
  `audit_rooms.png` and `audit_contact.png`: every primary CTA button on the page
  visibly washes out to a pale, low-contrast pink partway through its animation cycle,
  continuously, forever.
- **Idle animation count:** 7 elements animating at rest with no user interaction —
  5× `.btn-gold` `shine` (3s, infinite) + 3× `.testimonial-card` `floating` (3s,
  infinite) (measured via `getComputedStyle().animationName` across the whole DOM).
  Neither keyframe definition (`index.html.erb:109`, `:119`) is gated behind a
  `prefers-reduced-motion` media query — confirmed absent via
  `grep -n "prefers-reduced-motion"` across the view and `application.css`.
- **States checklist:**
  - Empty state: present (`activities.empty_state`, `index.html.erb:615`).
  - Focus state: present and correct on every form field
    (`focus:outline-none focus:ring-2 focus:ring-[var(--color-accent)]`,
    e.g. `:896-963`).
  - Loading/disabled state: not applicable — the booking form is a synchronous
    client-side link-builder (wa.me / mailto), no async submission exists to need one.
  - Error state: relies on native `form.reportValidity()` (`booking_modal.js:98`) —
    no custom error styling, acceptable given the form's simplicity.
  - Success state: none — sending closes the modal and hands off to WhatsApp/email
    with no in-page confirmation. Reasonable given the handoff is to an external app.
  - Landmark/skip-link: **no `<main>` element anywhere** in the layout or homepage
    view (`grep -n "<main"` returned nothing), and no skip-link. 18 `aria-label`s
    present on icon-only controls (`grep -c "aria-label"`).
  - Uncertain: the Google Maps embed (`index.html.erb` `#contacto`, `</iframe>` near
    `:695`) rendered as a **blank gray box** in the headless-Chromium screenshot
    (`audit_contact.png`) — could be a headless-browser/API-key artifact rather than a
    real production bug; flagged as unresolved, needs a live-browser check with a real
    viewer session before treating as confirmed.

## 3. Copy & Honesty Evidence

- **Codebase fallback copy contains marketing superlatives** not backed by anything
  shown elsewhere: `"Una experiencia de lujo en el corazón histórico de Querétaro"`
  (`home_hero_subtitle` default), `"Habitaciones Premium"` (`home_features_subtitle`
  default), `"Experiencias Extraordinarias"` (`services_subtitle` default) —
  `index.html.erb:285, 327, 528`. The SEO meta description default, by contrast, is
  modest: `"Habitaciones cómodas, atención cercana y la mejor ubicación..."`
  (`config/locales/es.yml:86`) — an internal inconsistency in the shipped *defaults*.
- **What's actually live is more honest than the defaults:** the deployed hero
  subtitle currently reads `"Hotel ubicado en el centro histórico de Queretaro con
  amplio estacionamiento privado dentro de las instalaciones sin costo adicional para
  su viaje de negocios o turismo."` — a plain, factual, non-inflated description
  (captured in `audit_hero.png`), confirming the admin has already overridden the
  puffier fallback via Easy Edit.
- **No dark patterns found:** no fake scarcity/countdown, no forced continuity, no
  hidden fees — pricing is shown plainly per room (`$720 MXN`, `$850 MXN`, etc., visible
  directly on each room card in `audit_rooms.png`), and `cta_button_enabled?` genuinely
  hides a contact channel rather than faking its unavailability
  (`app/helpers/application_helper.rb:63-67`).

## 4. Weight & Friction Evidence (live, measured)

- **Total page weight: 47.86MB** across 132 network requests on first load.
- **Image weight: 45.48MB** (95% of total) — 8 images alone exceed 2MB each; the
  single largest is **8.1MB** (the hero background PNG). No ActiveStorage variants are
  used anywhere (confirmed in the prior technical audit this session,
  `url_for(photo)` used directly with no `.variant()` call).
- **CSS: 18KB, fonts: 305KB.** JS byte total could not be reliably measured this pass
  (many script responses lack a `Content-Length` header under `networkidle0` capture);
  flagged as a measurement gap, not a zero finding.
- **Time to network-idle: 7,366ms** on a synthetic connection with no throttling —
  real-world mobile load time will be substantially worse given the image weight above.
- **2 infinite CSS animation systems** running simultaneously at idle (see Visual
  Evidence above) — continuous GPU/battery use with no motion-preference gate.

## 5. Accessibility Evidence

- **Contrast:** all text-on-surface pairs pass comfortably as of this pass (accent vs.
  all three backgrounds ≥6.2:1, per the validation added to `Theme` earlier this
  session) — *except* the newly-found accent-vs-hero-photo case above, which isn't
  (and can't be) covered by the flat-color contrast validator.
- **Keyboard/focus:** every form control has a visible focus ring
  (`focus:ring-[var(--color-accent)]`). Icon-only controls (modal close, gallery
  prev/next, language globe) carry `aria-label` — 18 instances counted.
- **Landmarks:** no `<main>` element, no skip-link. `<nav>`, `<footer>` present.
- **Reduced motion:** not respected — see idle-animation finding above.

## Known gaps

- JS byte total not reliably measured (see Weight & Friction).
- Google Maps embed's blank appearance is unconfirmed as a real bug vs. a
  headless-browser artifact.
- Evidence gathered directly by the orchestrator (this session) rather than via
  isolated subagents, given pre-existing deep familiarity with this exact codebase
  from the same session — a deliberate efficiency tradeoff, not an oversight.
