class CreatePageContents < ActiveRecord::Migration[8.1]
  def change
    create_table :page_contents do |t|
      t.string :key
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
