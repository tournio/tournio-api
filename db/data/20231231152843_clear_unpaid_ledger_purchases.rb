# frozen_string_literal: true

class ClearUnpaidLedgerPurchases < ActiveRecord::Migration[7.1]
  def up
    Tournament.active.each do |t|
      t.purchasable_items.ledger.each do |pi|
        pi.purchases.unpaid.each do |p|
          # pi.purchases.unpaid.destroy_all
          ap "#{t.identifier} / #{p.name} / #{p.bowler.last_name}"
        end
        ap "Unpaid total: #{pi.purchases.unpaid.count}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
