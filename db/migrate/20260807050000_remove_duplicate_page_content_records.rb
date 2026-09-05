class RemoveDuplicatePageContentRecords < ActiveRecord::Migration[8.1]
  def change
    # Keep the latest record for each key based on updated_at timestamp
    execute <<-SQL
      DELETE FROM page_contents
      WHERE id NOT IN (
        SELECT MAX(id) FROM page_contents GROUP BY key
      );
    SQL
  end
end
