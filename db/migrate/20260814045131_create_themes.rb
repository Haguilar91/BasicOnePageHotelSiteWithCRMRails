class CreateThemes < ActiveRecord::Migration[8.1]
  def change
    create_table :themes do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :bg_primary, null: false
      t.string :bg_secondary, null: false
      t.string :bg_tertiary, null: false
      t.string :accent, null: false
      t.string :accent_soft, null: false
      t.string :text_muted, null: false
      t.boolean :active, null: false, default: false
      t.integer :position

      t.timestamps
    end

    add_index :themes, :slug, unique: true
    add_index :themes, :active
  end
end
