class AddImageIconRoomTypesToPageContents < ActiveRecord::Migration[8.1]
  def change
    # These columns are redundant - ActiveStorage handles attachments via has_one_attached
    # add_column :page_contents, :logo, :string
    # add_column :page_contents, :favicon, :string
    # add_column :page_contents, :app_icon, :string
  end
end
