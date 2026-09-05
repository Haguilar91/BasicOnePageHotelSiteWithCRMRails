require "test_helper"

class SeoTest < ActionDispatch::IntegrationTest
  # --- canonical ---------------------------------------------------------
  #
  # The reason this file exists: several routes reach the same page, and left
  # undeclared a crawler treats them as separate pages competing with one
  # another. Each group below must collapse onto a single canonical URL.

  test "every route that renders the Spanish homepage points at one canonical URL" do
    %w[/ /es /home/index /es/home/index].each do |path|
      get path
      assert_response :success
      assert_equal "http://www.example.com/", canonical, "for #{path}"
    end
  end

  test "every route that renders the English homepage points at one canonical URL" do
    %w[/en /en/home/index].each do |path|
      get path
      assert_response :success
      assert_equal "http://www.example.com/en", canonical, "for #{path}"
    end
  end

  test "announcement pages are canonical to themselves, per locale" do
    announcement = create_announcement

    get announcement_path(id: announcement.id)
    assert_equal "http://www.example.com/announcements/#{announcement.id}", canonical

    get announcement_path(id: announcement.id, locale: :en)
    assert_equal "http://www.example.com/en/announcements/#{announcement.id}", canonical
  end

  # --- hreflang ----------------------------------------------------------

  test "each page lists every locale plus x-default, and does so reciprocally" do
    expected = {
      "es" => "http://www.example.com/",
      "en" => "http://www.example.com/en",
      "x-default" => "http://www.example.com/"
    }

    # Google requires the set to be identical on every language version,
    # including a self-reference — a one-way hreflang is ignored outright.
    %w[/ /en].each do |path|
      get path
      assert_equal expected, alternates, "for #{path}"
    end
  end

  test "hreflang follows the page, not just the homepage" do
    announcement = create_announcement
    get announcement_path(id: announcement.id)

    assert_equal "http://www.example.com/announcements/#{announcement.id}", alternates["es"]
    assert_equal "http://www.example.com/en/announcements/#{announcement.id}", alternates["en"]
  end

  # --- title and description ---------------------------------------------

  test "the homepage title is the site name alone, without repeating it" do
    create_es(PageContent, key: "site_title", content: "Hotel Mesón del Bosque")

    get root_path
    assert_equal "Hotel Mesón del Bosque", title
  end

  test "inner pages put their own name in front of the site name" do
    create_es(PageContent, key: "site_title", content: "Hotel Mesón del Bosque")
    get announcements_path

    assert_equal "Anuncios · Hotel Mesón del Bosque", title
  end

  test "a page's own description wins over the site default" do
    announcement = create_announcement(description: "20% de descuento en julio")
    get announcement_path(id: announcement.id)

    assert_equal "20% de descuento en julio", description
  end

  test "the homepage description is editable from the admin panel" do
    create_es(PageContent, key: "meta_description", content: "Hotel boutique en el centro de Querétaro.")

    get root_path
    assert_equal "Hotel boutique en el centro de Querétaro.", description
  end

  test "the description falls back to a translated default when nothing is set" do
    get root_path
    assert_equal I18n.t("seo.default_description", locale: :es), description

    get root_path(locale: :en)
    assert_equal I18n.t("seo.default_description", locale: :en), description
  end

  test "an over-long description is cut on a word boundary" do
    create_es(PageContent, key: "meta_description", content: "palabra " * 60)

    get root_path
    assert_operator description.length, :<=, 160
    assert description.end_with?("…"), description
    assert_not description.include?("palabr…"), "should not cut mid-word"
  end

  test "HTML in the admin's copy never leaks into the meta tags" do
    create_es(PageContent, key: "meta_description", content: "<b>Hotel</b> boutique")

    get root_path
    assert_equal "Hotel boutique", description
  end

  # --- link previews -----------------------------------------------------

  test "the page carries Open Graph and Twitter cards" do
    get root_path

    assert_equal "website", meta_property("og:type")
    assert_equal "http://www.example.com/", meta_property("og:url")
    assert_equal "es_MX", meta_property("og:locale")
    assert_equal "en_US", meta_property("og:locale:alternate")
    assert_equal "summary_large_image", meta_name("twitter:card")
  end

  test "the English page declares the English locale" do
    get root_path(locale: :en)

    assert_equal "en_US", meta_property("og:locale")
    assert_equal "es_MX", meta_property("og:locale:alternate")
    assert_select "html[lang=?]", "en"
  end

  # --- structured data ---------------------------------------------------

  test "the homepage carries valid Hotel structured data built from real records" do
    create_es(PageContent, key: "site_title", content: "Hotel Mesón del Bosque")
    create_es(PageContent, key: "address_line", content: "Allende Norte 82, Querétaro")
    create_es(PageContent, key: "contact_email", content: "hola@example.com")
    create_es(Feature, title: "Wi-Fi gratis")
    PhoneNumber.create!(number: "+52 442 212 3456", call_active: true)

    get root_path
    data = JSON.parse(json_ld)

    assert_equal "https://schema.org", data["@context"]
    assert_equal "Hotel", data["@type"]
    assert_equal "Hotel Mesón del Bosque", data["name"]
    assert_equal "http://www.example.com/", data["url"]
    assert_equal "+524422123456", data["telephone"], "should use the flagged call line"
    assert_equal "hola@example.com", data["email"]
    assert_equal "Allende Norte 82, Querétaro", data.dig("address", "streetAddress")
    assert_equal "PostalAddress", data.dig("address", "@type")
    assert_includes data["amenityFeature"].map { |f| f["name"] }, "Wi-Fi gratis"
  end

  test "structured data stays off the pages it does not describe" do
    get announcements_path
    assert_select 'script[type="application/ld+json"]', false
  end

  test "structured data omits contact fields that are not filled in" do
    get root_path
    data = JSON.parse(json_ld)

    # compact_blank must drop empty keys rather than emit nulls, which
    # Google's validator flags.
    assert_not data.key?("email")
    assert_not data.value?(nil)
  end

  # --- sitemap and robots ------------------------------------------------

  test "the sitemap lists each page once with all of its locales" do
    announcement = create_announcement

    get sitemap_path
    assert_response :success
    assert_equal "application/xml", response.media_type

    doc = Nokogiri::XML(response.body)
    locs = doc.css("url > loc").map(&:text)
    assert_includes locs, "http://www.example.com/"
    assert_includes locs, "http://www.example.com/announcements"
    assert_includes locs, "http://www.example.com/announcements/#{announcement.id}"
    assert_equal locs.uniq, locs, "no page should be listed twice"

    home = doc.css("url").find { |u| u.at_css("loc").text == "http://www.example.com/" }
    langs = home.xpath("./*[local-name()='link']").map { |l| l["hreflang"] }
    assert_equal %w[es en x-default], langs
  end

  test "the sitemap leaves out announcements that are switched off" do
    hidden = create_announcement(active: false)

    get sitemap_path
    assert_not_includes response.body, "/announcements/#{hidden.id}<"
  end

  test "robots keeps non-production deployments out of the index entirely" do
    # A staging copy on a public URL would otherwise be indexed and compete
    # with the real site for its own content.
    get robots_path
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_match(/User-agent: \*\nDisallow: \/\n/, response.body)
    assert_no_match(/Sitemap:/, response.body)
  end

  test "robots opens the site up and points at the sitemap in production" do
    with_production_host do
      get robots_path

      assert_match(/Sitemap: https:\/\/hotel\.example\/sitemap\.xml/, response.body)
      assert_match(%r{Disallow: /avo}, response.body)
      assert_no_match(/^Disallow: \/$/, response.body)
    end
  end

  # --- deployed host -----------------------------------------------------

  test "SITE_HOST overrides the request host in every canonical URL" do
    # Without this the site can be indexed under whatever Host header
    # arrives — an IP, a staging domain, or an attacker-supplied value.
    with_production_host do
      get root_path
      assert_equal "https://hotel.example/", canonical
      assert_equal "https://hotel.example/en", alternates["en"]
    end
  end

  private

  def create_announcement(**overrides)
    create_es(Announcement, **{
      title: "Temporada de verano", description: "20% de descuento",
      start_date: Date.current, end_date: Date.current + 30, active: true
    }.merge(overrides))
  end

  def with_production_host
    original_env = Rails.env
    Rails.env = "production"
    ENV["SITE_HOST"] = "hotel.example"
    yield
  ensure
    ENV.delete("SITE_HOST")
    Rails.env = original_env
  end

  def title = css_select("title").first.text
  def canonical = css_select('link[rel="canonical"]').first["href"]
  def description = css_select('meta[name="description"]').first["content"]
  def json_ld = css_select('script[type="application/ld+json"]').first.text
  def meta_property(name) = css_select("meta[property='#{name}']").first&.[]("content")
  def meta_name(name) = css_select("meta[name='#{name}']").first&.[]("content")

  def alternates
    css_select('link[rel="alternate"]').to_h { |link| [ link["hreflang"], link["href"] ] }
  end
end
