# frozen_string_literal: true

class CreateEventSignups < ActiveRecord::Migration[7.1]
  def up
    Tournament.active.each do |t|
      t.bowlers.each do |b|
        # create signups for all the events, including scratch masters.
        # Each bowler gets a Signup object for every PurchasableItem with a category of Bowling
        t.purchasable_items.bowling.each do |pi|
          Signup.create(
            bowler: b,
            purchasable_item: pi
          )
        end

        # for everything a bowler has bought, sign them up and mark it as paid
        b.purchases.each do |p|
          signup = b.signups.find_by(purchasable_item_id: p.purchasable_item_id)
          signup.pay! if signup.present?
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
