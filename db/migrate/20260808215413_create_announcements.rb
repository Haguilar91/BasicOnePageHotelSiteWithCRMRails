class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.text :title
      t.text :description
      t.date :start_date
      t.datetime :end_date
      t.boolean :active

      t.timestamps
    end
  end
end
