class RemoveRedundantColumnsFromPageContents < ActiveRecord::Migration[8.1]
  def change
    remove_column :page_contents, :logo, :string
    remove_column :page_contents, :favicon, :string
    remove_column :page_contents, :app_icon, :string
  end
end
