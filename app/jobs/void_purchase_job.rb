# frozen_string_literal: true

class VoidPurchaseJob
  include Sidekiq::Job

  def perform(purchase_id, why)
    p = Purchase.find(purchase_id)
    p.update(voided_at: Time.zone.now, void_reason: why) unless p.paid_at.present? || p.voided_at.present?
  end
end
