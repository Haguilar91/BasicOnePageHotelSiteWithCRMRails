class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.string :title
      t.text :description
      t.decimal :price

      t.timestamps
    end
  end
end
