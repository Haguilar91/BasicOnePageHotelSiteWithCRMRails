class AddValidFromToOffers < ActiveRecord::Migration[8.1]
  def change
    # Pairs with valid_until: an offer only shows on the site inside the
    # window. Left blank it starts immediately, matching existing offers.
    add_column :offers, :valid_from, :date
  end
end
