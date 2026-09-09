class SeedActivitiesSectionPageContent < ActiveRecord::Migration[8.1]
  # Every other homepage section's title/subtitle (rooms, services, location,
  # CTA...) has a seeded `page_content` row, which is what makes it show up
  # in /translations (that panel only lists PageContent records that already
  # exist) and pre-populates Easy Edit. The "Qué hacer" (Activities) section's
  # title and subtitle were never seeded, even though the view already reads
  # them via `editable_content` — so they were stuck rendering only the
  # Spanish default baked into the view, uneditable and untranslatable, on
  # every environment that's already been seeded (this data gap doesn't fix
  # itself just by deploying new code, hence a migration rather than only a
  # db/seeds.rb change).
  def up
    PageContent.find_or_create_by!(key: "home_activities_title") do |p|
      p.title = "Activities Section Title"
      p.content = "Qué hacer en Querétaro"
    end
    PageContent.find_or_create_by!(key: "home_activities_subtitle") do |p|
      p.title = "Activities Section Subtitle"
      p.content = "Restaurantes, puntos de interés y tours que hacen único tu viaje a Querétaro."
    end
  end

  def down
    PageContent.where(key: %w[home_activities_title home_activities_subtitle]).destroy_all
  end
end
