# frozen_string_literal: true

class AddPurchasableItemToBowlerJob
  class OneTimePurchaseOnlyError < RuntimeError
  end

  include Sidekiq::Job

  def perform(bowler_id, purchasable_item_id)
    ap "Doing my thing..."
    bowler = Bowler.includes(
      tournament: [:purchasable_items],
      purchases: [:purchasable_item]
    ).find(bowler_id)
    tournament = bowler.tournament
    item = tournament.purchasable_items.find(purchasable_item_id)

    if bowler.purchases.one_time.pluck(:purchasable_item_id).include?(purchasable_item_id)
      raise OneTimePurchaseOnlyError.new("Bowler already has #{item.name} in their purchase history, and it's a one-timer.")
    end

    bowler.purchases << Purchase.create(purchasable_item: item)

    bowler.ledger_entries << LedgerEntry.new(
      debit: item.value,
      source: :automatic,
      identifier: item.name
    )
  end
end
