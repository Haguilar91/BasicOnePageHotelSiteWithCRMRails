# Hotel Mesón del Bosque

Rails 8 site and admin panel for Hotel Mesón del Bosque, a boutique hotel in
the historic center of Querétaro, Mexico. Public marketing site (rooms,
offers, local activities, announcements) in Spanish and English, plus an
admin panel non-technical staff use to edit all of it.

## Stack

- **Rails 8.1**, Ruby 3.4 (see [.ruby-version](.ruby-version))
- **SQLite** in production (via `DATABASE_URL`/`config/database.yml`) — no
  separate database server to run
- **Propshaft** + Tailwind for assets, no JS bundler and no Node — plain
  `<script>`-style JS lives in `app/assets/javascripts/`, included per-page
  via `javascript_include_tag`
- **Devise** for authentication (staff-only; there's no public sign-up)
- **[Avo](https://avohq.io)** for the admin panel (`/avo`) — resources live
  in `app/avo/resources`
- **[Mobility](https://github.com/shioyama/mobility)** (`key_value`
  backend) for bilingual (ES/EN) content on `Room`, `Feature`, `Experience`,
  `LocalActivity`, `Offer`, `Announcement`, `PageContent`
- **ActiveStorage**, local disk service, for photos

## Getting started

```bash
git clone <this repo>
cd hotel_meson
bin/setup
```

`bin/setup` installs gems, prepares the database (creates + migrates +
seeds `db/seeds.rb` if empty) and starts the dev server on
<http://localhost:3000>.

You'll need two things `bin/setup` can't provide:

- **`config/master.key`** — decrypts `config/credentials.yml.enc`. Ask a
  teammate for it, or if this is a brand-new install, remove
  `config/credentials.yml.enc` and run `bin/rails credentials:edit` to
  generate a fresh pair.
- **`.envrc`** (gitignored, read via [direnv](https://direnv.net) or your
  own shell) — sets `RAILS_MASTER_KEY` and `DEVISE_SECRET_KEY` for local
  dev. `RAILS_MASTER_KEY` should match `config/master.key` above;
  `DEVISE_SECRET_KEY` can be any long random string locally.

A default admin user is seeded: `admin@hotel.com` / `password123`.

## Running tests

```bash
bin/rails test        # unit + integration tests (test/)
bin/ci                # what CI runs: setup, tests, then a seed replant check
```

## Project layout, beyond the Rails defaults

- **`app/avo/resources/`** — Avo admin resource definitions (one per
  admin-editable model).
- **`app/controllers/easy_edit_controller.rb`** — "Easy Edit": a WYSIWYG-ish
  overlay on the *live* public site that lets a signed-in admin click a
  pencil icon on a room/offer/etc. card and edit it in a modal, without
  leaving the page or opening Avo.
- **`app/controllers/translations_controller.rb`** — a `/translations`
  panel for filling in the English side of bilingual content; English falls
  back to Spanish (via Mobility's `fallbacks`) until it's filled in.
- **`app/controllers/docs_controller.rb`** — an in-app `/docs` guide (for
  hotel staff, not developers) covering Avo, Easy Edit, phone numbers, SEO.
- **`config/routes.rb`** — public routes live under a `scope
  "(:locale)"` (optional `/es`/`/en` prefix, for SEO-visible URLs); anything
  content-editing (Avo, Easy Edit, Translations) lives behind `authenticate
  :user do`, unscoped by locale.
- **`config/initializers/site_host.rb`** — the one canonical domain every
  absolute URL (canonical links, hreflang, Open Graph, sitemap) is built
  from; overridable via `SITE_HOST` for a staging deploy.
- **`db/seeds.rb`** — the hotel's actual current rooms/offers/features/
  activities/theme, used both to seed a fresh database and as the fixture
  data `bin/ci`'s seed-replant check exercises.

## Deploying

Two ways to ship this, both Docker-based:

- **[DEPLOY.md](DEPLOY.md)** — the current one: `./deploy.sh` on a
  self-hosted server, via `docker compose`.
- **[KAMAL.md](KAMAL.md)** — an alternate path via
  [Kamal](https://kamal-deploy.org), deploying over SSH to any server
  without a script living on that server. Not yet wired up to a real
  server/registry — see that file for the setup steps.
