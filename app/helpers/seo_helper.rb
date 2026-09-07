# Everything the <head> needs to describe a page to search engines and to
# link previews (WhatsApp, Facebook, X). Two problems drive most of this:
#
#   1. The same page answers on several URLs — "/", "/es", "/home/index" and
#      "/es/home/index" all render the Spanish homepage, and "/en" plus
#      "/en/home/index" render the English one. Left alone, a crawler treats
#      those as separate pages competing with each other, so every page
#      declares one <link rel="canonical"> pointing at its clean form.
#
#   2. The site is the same content in two languages. `hreflang` is what
#      tells Google that "/" and "/en" are translations of one another
#      rather than duplicates, and which one to serve to which visitor —
#      the payoff for putting the locale in the path (see config/routes.rb).
#
# Controllers declare how to build their own URL per locale via
# ApplicationController#seo_canonical; everything here builds on that.
module SeoHelper
  # Canonical URLs must name one host, not whichever Host header arrived —
  # otherwise the site can be indexed under an IP, a staging domain, or an
  # attacker-supplied header. That host is config.x.site_host (see
  # config/initializers/site_host.rb), overridable with the SITE_HOST
  # environment variable.
  #
  # Only production uses it. Development and test fall back to the request's
  # own host so local links stay clickable and tests aren't pinned to the
  # real domain — setting SITE_HOST explicitly forces the production
  # behaviour anywhere, which is how that path gets tested.
  def seo_host_options
    configured = ENV["SITE_HOST"].presence
    configured ||= Rails.configuration.x.site_host if Rails.env.production?
    return { host: request.host_with_port, protocol: request.protocol } if configured.blank?

    host, _, port = configured.rpartition(":")
    host.presence ? { host: host, port: port, protocol: "https" } : { host: configured, protocol: "https" }
  end

  # Whether this deploy is the real, public site — that is, it is answering on
  # the very domain its canonical URLs name.
  #
  # This is what decides whether robots.txt opens the site up. Deriving it
  # from the host, rather than from "is some env var set?", means a second
  # copy of the site can never invite crawlers in: a staging deploy, a preview
  # URL or the site reached by raw IP all answer on a different host than the
  # canonical one, so they serve "Disallow: /" without anyone having to
  # remember to configure them. It also means the real site needs no
  # configuration to be indexed.
  def canonical_host?
    return false unless Rails.env.production?

    strip_www(request.host) == strip_www(seo_host_options[:host].to_s)
  end

  # Whether crawlers should be let in at all.
  #
  # Answering on the canonical domain is necessary but not always sufficient:
  # a site can be up on its real host and still not be ready to be found —
  # the pre-launch case, where the deploy is live for the people reviewing it
  # but shouldn't be turning up in search yet. ALLOW_INDEXING=false holds the
  # door shut without having to lie about the domain in every canonical URL.
  def indexable?
    canonical_host? && ENV["ALLOW_INDEXING"] != "false"
  end

  # "www.example.com" and "example.com" are the same site for this purpose.
  # Without this, a crawler that fetched robots.txt from the www variant
  # (when no redirect is in place) would be told the site is closed.
  def strip_www(host) = host.to_s.downcase.delete_prefix("www.")

  # Spanish is the default locale and its URLs stay bare ("/" not "/es/"),
  # so the canonical form of a Spanish page carries no locale segment.
  def seo_locale_param(locale)
    locale.to_s == I18n.default_locale.to_s ? nil : locale.to_s
  end

  def seo_url(locale = I18n.locale)
    builder = @seo_canonical || ->(options) { root_url(**options) }
    builder.call(seo_host_options.merge(locale: seo_locale_param(locale)))
  end

  def canonical_url = seo_url(I18n.locale)

  # Every locale this page exists in, plus x-default for crawlers that can't
  # match any of them. Google wants the set to be complete and reciprocal:
  # each language's page must list all of them, including itself.
  def hreflang_alternates
    I18n.available_locales.map { |locale| [ locale.to_s, seo_url(locale) ] } +
      [ [ "x-default", seo_url(I18n.default_locale) ] ]
  end

  # <title>. Pages set `content_for :title` with their own name; the site
  # name is appended so a result in a crowded SERP still says which hotel it
  # is, and the homepage shows the site name alone rather than repeating it.
  def seo_title
    site_name = strip_tags(page_content("site_title", t("seo.site_name"))).to_s.strip
    page = content_for(:title).presence&.to_s&.strip

    page.blank? || page == site_name ? site_name : "#{page} · #{site_name}"
  end

  # The snippet under the result. Set per page via @seo_description; the
  # homepage falls back to an admin-editable PageContent so the copy that
  # search engines show is maintained in the same place as the rest of the
  # site's text, not buried in a template.
  def seo_description
    raw_text = @seo_description.presence || page_content("meta_description", t("seo.default_description"))
    text = strip_tags(raw_text.to_s).squish
    # Google truncates around 160 characters; cutting on a word boundary
    # keeps the tag from ending mid-word.
    text.length > 160 ? "#{text[0, 157].sub(/\s+\S*\z/, '')}…" : text
  end

  # The image link previews use. Prefers whatever the page itself is about
  # (an announcement's photo), then the hero image, then the hotel's logo.
  def seo_image_url
    source = @seo_image
    source ||= @hero_image&.image if @hero_image&.image&.attached?
    source ||= begin
      global = PageContent.find_by(key: "global")
      global&.logo if global&.logo&.attached?
    end
    return nil if source.nil?

    url_for(source).start_with?("http") ? url_for(source) : "#{request.base_url}#{url_for(source)}"
  rescue StandardError
    nil
  end

  # schema.org/Hotel. This is what can turn a plain blue link into a result
  # carrying the phone number, address and rating — worth far more for a
  # single-location hotel than for most sites, since "hotel in <city>" is
  # exactly the kind of query these fields answer.
  def hotel_json_ld
    data = {
      "@context" => "https://schema.org",
      "@type" => "Hotel",
      "name" => strip_tags(page_content("site_title", t("seo.site_name"))).to_s.strip,
      "description" => seo_description,
      "url" => seo_url(I18n.locale),
      "address" => {
        "@type" => "PostalAddress",
        "streetAddress" => page_content("address_line"),
        "addressLocality" => page_content("address_locality", "Querétaro"),
        "addressCountry" => page_content("address_country", "MX")
      }.compact_blank,
      "email" => page_content("contact_email"),
      "telephone" => PhoneNumber.call_line&.dialable || PhoneNumber.dialable(page_content("contact_phone")),
      "priceRange" => page_content("price_range", "$$"),
      "image" => seo_image_url,
      "sameAs" => %w[social_facebook social_instagram social_twitter social_tiktok]
        .filter_map { |key| page_content(key).presence },
      "amenityFeature" => Feature.order(:position, :id).filter_map { |feature|
        next if feature.title.blank?

        { "@type" => "LocationFeatureSpecification", "name" => feature.title, "value" => true }
      }
    }.compact_blank

    data.to_json
  end
end
