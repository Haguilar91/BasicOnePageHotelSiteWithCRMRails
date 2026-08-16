# Non-destructive: the plain Spanish columns were superseded by Mobility's
# KeyValue translation store (see translations:backfill_es) but are kept
# around, renamed, as a rollback path for one release cycle rather than
# dropped outright.
class RenameTranslatedColumnsToLegacy < ActiveRecord::Migration[8.1]
  def change
    rename_column :rooms, :name, :name_legacy
    rename_column :rooms, :badge, :badge_legacy
    rename_column :rooms, :button_name, :button_name_legacy
    rename_column :rooms, :price, :price_legacy
    rename_column :rooms, :description, :description_legacy
    rename_column :rooms, :features, :features_legacy

    rename_column :page_contents, :content, :content_legacy

    rename_column :experiences, :title, :title_legacy
    rename_column :experiences, :description, :description_legacy

    rename_column :features, :title, :title_legacy
    rename_column :features, :description, :description_legacy

    rename_column :local_activities, :title, :title_legacy
    rename_column :local_activities, :description, :description_legacy

    rename_column :offers, :title, :title_legacy
    rename_column :offers, :badge, :badge_legacy
    rename_column :offers, :description, :description_legacy
    rename_column :offers, :ticker_description, :ticker_description_legacy

    rename_column :announcements, :title, :title_legacy
    rename_column :announcements, :description, :description_legacy
  end
end
