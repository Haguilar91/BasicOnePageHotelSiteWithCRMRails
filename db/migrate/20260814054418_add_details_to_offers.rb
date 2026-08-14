class AddDetailsToOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :offers, :badge, :string
    add_column :offers, :position, :integer
    add_column :offers, :active, :boolean, default: true, null: false
    add_column :offers, :valid_until, :date
    add_column :offers, :booking_url, :string
  end
end
