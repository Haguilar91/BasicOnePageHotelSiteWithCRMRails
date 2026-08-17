class AddCtaButtonTogglesToPageContents < ActiveRecord::Migration[8.1]
  def change
    add_column :page_contents, :show_cta_call, :boolean, default: true, null: false
    add_column :page_contents, :show_cta_whatsapp, :boolean, default: true, null: false
    add_column :page_contents, :show_cta_email, :boolean, default: true, null: false
  end
end
