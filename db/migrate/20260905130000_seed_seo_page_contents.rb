# Creates the PageContent rows behind the SEO tags so they show up in Avo
# ready to edit, the same way the rest of the site's copy does. Without a row
# the templates still render (SeoHelper falls back to the I18n defaults), but
# an admin would have no way to change the text search engines show.
class SeedSeoPageContents < ActiveRecord::Migration[8.1]
  KEYS = {
    "meta_description" => {
      title: "SEO — Descripción para buscadores",
      content: nil # falls back to t("seo.default_description") until edited
    },
    "address_locality" => { title: "SEO — Ciudad", content: "Querétaro" },
    "address_country" => { title: "SEO — País (código de 2 letras)", content: "MX" },
    "price_range" => { title: "SEO — Rango de precios ($ a $$$$)", content: "$$" }
  }.freeze

  def up
    KEYS.each do |key, attributes|
      record = PageContent.find_or_initialize_by(key: key)
      next if record.persisted?

      record.title = attributes[:title]
      record.save!
      Mobility.with_locale(:es) { record.update!(content: attributes[:content]) } if attributes[:content]
    end
  end

  def down
    PageContent.where(key: KEYS.keys).destroy_all
  end
end
