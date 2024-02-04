# frozen_string_literal: true

class CreateEntryFeePurchaseForFreeEntries < ActiveRecord::Migration[7.1]
  def up
    # for each upcoming tournament
    #   for each confirmed free entry in the tournament
    #     if the associated bowler has no entry-fee purchase, create one
    #     and mark it paid with the free entry's confirmation date
    Tournament.upcoming.each do |t|
      entry_fee_item = t.purchasable_items.entry_fee.first
      t.free_entries.where(confirmed: true).each do |fe|
        bowler = fe.bowler
        if bowler.purchases.entry_fee.blank?
          bowler.purchases << Purchase.new(
            purchasable_item: entry_fee_item,
            amount: entry_fee_item.value,
            paid_at: fe.updated_at
          )
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
