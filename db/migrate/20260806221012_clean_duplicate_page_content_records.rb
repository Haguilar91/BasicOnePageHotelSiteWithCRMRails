  class CleanDuplicatePageContentRecords < ActiveRecord::Migration[8.1]
    def change
      # Delete all duplicate records, keeping only the global brand settings
      # Using raw SQL to avoid loading the model and triggering Active Storage validation
      execute <<-SQL
        DELETE FROM page_contents 
        WHERE key != 'global'
      SQL
    end
  end
