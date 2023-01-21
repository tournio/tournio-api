# frozen_string_literal: true

class  SchedulePurchaseVoidsJob
  include Sidekiq::Job

  def perform(purchasable_item_id, why)
    pi = PurchasableItem.find(purchasable_item_id)
    pi.purchases.unpaid.each { |p| VoidPurchaseJob.perform_async(p.id, why) }
  end
end
