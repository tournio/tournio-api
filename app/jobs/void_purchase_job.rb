# frozen_string_literal: true

class VoidPurchaseJob
  include Sidekiq::Job

  def perform(purchase_id, why)
    p = Purchase.find(purchase_id)
    unless p.paid_at.present?
      p.update(voided_at: Time.zone.now, void_reason: why)

      # Having this be a debit assumes that the voided charge was a credit, such
      # as an early-registration discount. We shouldn't make that assumption!
      p.bowler.ledger_entries << LedgerEntry.new(
        debit: p.amount,
        identifier: p.identifier,
        notes: why,
        source: :void
      )
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.info "Could not find purchase with id=#{purchase_id}. Maybe it was already voided?"
  end
end
