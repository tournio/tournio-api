# frozen_string_literal: true

class ScheduleAutomaticLateFeesJob
  include Sidekiq::Job

  def perform(tournament_id)
    bowlers = Bowler.joins(purchases: :purchasable_item).where(tournament_id: tournament_id).merge(Purchase.unpaid).merge(PurchasableItem.entry_fee)

    late_fee_item = PurchasableItem.late_fee.where(tournament_id: tournament_id).first

    return unless late_fee_item.present?

    bowlers.each do |bowler|
      AddPurchasableItemToBowlerJob.perform_async(bowler.id, late_fee_item.id) unless bowler.purchases.late_fee.any?
    end
  end
end
