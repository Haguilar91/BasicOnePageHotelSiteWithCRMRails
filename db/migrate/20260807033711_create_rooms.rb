class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :name
      t.text :description
      t.string :price
      t.text :features
      t.string :booking_url
      t.string :badge
      t.integer :position

      t.timestamps
    end
  end
end
