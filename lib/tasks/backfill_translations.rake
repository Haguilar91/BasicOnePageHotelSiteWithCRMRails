namespace :translations do
  # Source columns were renamed to a `_legacy` suffix (see
  # RenameTranslatedColumnsToLegacy) after their data was superseded by
  # Mobility's translation store, precisely so this task stays re-runnable
  # (e.g. against a restored/reset database) without depending on column
  # names that only existed pre-rename.
  desc "Backfill existing Spanish column data into Mobility's translation store"
  task backfill_es: :environment do
    targets = {
      Room => %i[name badge button_name price description features],
      PageContent => %i[content],
      Experience => %i[title description],
      Feature => %i[title description],
      LocalActivity => %i[title description],
      Offer => %i[title badge description ticker_description],
      Announcement => %i[title description],
      GalleryPhoto => %i[caption]
    }

    Mobility.with_locale(:es) do
      targets.each do |model, columns|
        updated = 0

        model.find_each do |record|
          next if columns.all? { |col| record.public_send(col).present? }

          columns.each do |col|
            next if record.public_send(col).present?

            legacy_value = record.read_attribute("#{col}_legacy")
            record.public_send("#{col}=", legacy_value) if legacy_value.present?
          end

          record.save!(validate: false)
          updated += 1
        end

        puts "#{model.name}: backfilled #{updated} record(s)"
      end
    end
  end
end
