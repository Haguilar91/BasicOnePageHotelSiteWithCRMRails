# `title` and `description` moved to Mobility's KeyValue translation store in
# 20260816203604 (the plain columns were kept, renamed `*_legacy`, as a
# rollback path). Their NOT NULL constraints came along for the ride, but
# nothing writes those columns any more — so creating or duplicating a
# LocalActivity from Avo blew up with "SQLite3::ConstraintException: NOT NULL
# constraint failed: local_activities.title_legacy" even though every field
# in the form was filled in.
#
# Only local_activities had NOT NULL on its translated columns; the other
# tables in that rename were already nullable, which is why this bug showed
# up on "Qué hacer" (Restaurantes/Puntos de Interés/Tours) and nowhere else.
class RelaxLegacyColumnConstraintsOnLocalActivities < ActiveRecord::Migration[8.1]
  def up
    change_column_null :local_activities, :title_legacy, true
    change_column_null :local_activities, :description_legacy, true
  end

  def down
    # Backfill from the Spanish translations so the constraint can go back on
    # without tripping over rows created while it was lifted.
    execute <<~SQL
      UPDATE local_activities
      SET title_legacy = COALESCE(title_legacy, (
        SELECT value FROM mobility_string_translations
        WHERE translatable_type = 'LocalActivity'
          AND translatable_id = local_activities.id
          AND key = 'title' AND locale = 'es'
      ), ''),
      description_legacy = COALESCE(description_legacy, (
        SELECT value FROM mobility_text_translations
        WHERE translatable_type = 'LocalActivity'
          AND translatable_id = local_activities.id
          AND key = 'description' AND locale = 'es'
      ), '')
    SQL

    change_column_null :local_activities, :title_legacy, false
    change_column_null :local_activities, :description_legacy, false
  end
end
