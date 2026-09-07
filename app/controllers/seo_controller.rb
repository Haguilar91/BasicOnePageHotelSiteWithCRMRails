# /sitemap.xml and /robots.txt.
#
# Both are generated rather than checked into public/, for one reason each:
# the sitemap has to list every page in every locale (and that set changes as
# announcements come and go), and robots.txt has to name the sitemap by its
# absolute URL, which depends on the host the site is deployed under.
#
# Generating robots.txt also lets it close the door on any copy of the site
# that isn't the real one: it opens up only when the deploy is answering on
# the domain its own canonical URLs name (SeoHelper#canonical_host?), so a
# staging copy — even one restored from a production database — serves
# "Disallow: /" without anyone having to configure it.
class SeoController < ApplicationController
  layout false

  def sitemap
    @entries = sitemap_entries
    render formats: [ :xml ]
  end

  def robots
    render plain: robots_body, content_type: "text/plain"
  end

  private

  # Each entry is one canonical page plus every locale it exists in, so the
  # sitemap carries the same hreflang information the pages themselves do —
  # which is what Google recommends for a multilingual site.
  def sitemap_entries
    pages = [
      { builder: ->(options) { root_url(**options) }, changefreq: "weekly", priority: "1.0" },
      { builder: ->(options) { announcements_url(**options) }, changefreq: "weekly", priority: "0.7" }
    ]

    pages += Announcement.where(active: true).order(:id).map do |announcement|
      {
        builder: ->(options) { announcement_url(announcement, **options) },
        changefreq: "monthly",
        priority: "0.5",
        lastmod: announcement.updated_at
      }
    end

    pages.map do |page|
      alternates = I18n.available_locales.to_h do |locale|
        [ locale.to_s, page[:builder].call(host_options.merge(locale: locale_param(locale))) ]
      end

      page.merge(loc: alternates[I18n.default_locale.to_s], alternates: alternates)
    end
  end

  def robots_body
    lines = [ "# https://www.robotstxt.org/robotstxt.html" ]

    if helpers.indexable?
      lines << "User-agent: *"
      # Admin and staff-only surfaces: all of these redirect to a login form,
      # so letting crawlers walk them wastes crawl budget on nothing.
      lines << "Disallow: /avo"
      lines << "Disallow: /easy_edit"
      lines << "Disallow: /translations"
      lines << "Disallow: /docs"
      lines << "Disallow: /users"
      lines << ""
      lines << "Sitemap: #{sitemap_url(**host_options)}"
    else
      # Anything that isn't the real production site — staging, a preview
      # deploy, the site reached by raw IP, a developer's laptop — stays out
      # of the index entirely, so a second copy can never compete with the
      # real one for its own content — as does a site held back before
      # launch with ALLOW_INDEXING=false. See SeoHelper#indexable?.
      lines << "User-agent: *"
      lines << "Disallow: /"
    end

    "#{lines.join("\n")}\n"
  end

  def host_options = helpers.seo_host_options
  def locale_param(locale) = helpers.seo_locale_param(locale)
end
