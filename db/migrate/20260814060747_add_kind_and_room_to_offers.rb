class AddKindAndRoomToOffers < ActiveRecord::Migration[8.1]
  def change
    # Existing offers were all standalone packages.
    add_column :offers, :kind, :string, default: "package", null: false
    add_reference :offers, :room, foreign_key: true, null: true

    # Room offers: the discounted price is derived from the room's price at
    # render time, so a room price change never leaves a stale figure behind.
    add_column :offers, :discount_percent, :integer

    add_column :offers, :show_on_ticker, :boolean, default: false, null: false
    add_column :offers, :ticker_description, :text

    add_index :offers, :kind
    add_index :offers, :show_on_ticker
  end
end
