# frozen_string_literal: true

class ClearUnpaidLedgerPurchases < ActiveRecord::Migration[7.1]
  def up
    Tournament.active.each do |t|
      t.purchasable_items.ledger.each do |pi|
        pi.purchases.unpaid.each do |p|
          pi.purchases.unpaid.destroy_all
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
