# Scope — Hotel Mesón del Bosque public homepage

**Audited surface:** live production preview at `https://hotelmeson.hectoraguilar.dev/`
(single long-scrolling page, ES locale). Source: `app/views/home/index.html.erb` (1,160
lines), `app/views/layouts/application.html.erb`, `app/models/theme.rb`,
`app/assets/stylesheets/application.css`.

**Primary user:** a prospective guest researching a boutique hotel stay in the historic
center of Querétaro — arriving from a search engine, WhatsApp share, or social link.

**Primary task:** understand what the hotel offers (room types, price, amenities,
location) and start a reservation — either via the in-page WhatsApp/Email modal or an
external booking link (Airbnb/Booking.com/custom).

**Constraints:**
- Rails 8 + Tailwind Play CDN (flagged in the prior technical audit as a perf issue,
  not scored here as a design defect on its own).
- Bilingual ES/EN via I18n + Mobility.
- Most visible content (colors, copy, photos) is admin-editable via Avo / Easy Edit by
  a non-technical hotel operator — confirmed live copy already diverges from the
  codebase's fallback strings, and the live theme's accent color was changed earlier
  this session per an admin-panel recommendation.
- Single scrolling page, anchor-nav between sections (no multi-page routing for the
  public marketing content).

**Reference designs / competitors:** none supplied by the user.

**Existing design status:** not a blank slate. This audit follows a session of prior
fixes (theme contrast auto-computation, CSS var opacity-modifier bug, robots.txt
indexing gate) — it evaluates what ships today, not what was originally intended.
