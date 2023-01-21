# frozen_string_literal: true

class VoidPurchaseJob
  include Sidekiq::Job

  def perform(purchase_id, why)
    p = Purchase.find(purchase_id)
    unless p.paid_at.present? || p.voided_at.present?
      p.update(voided_at: Time.zone.now, void_reason: why)
      p.bowler.ledger_entries << LedgerEntry.new(
        debit: p.amount,
        identifier: p.identifier,
        notes: why,
        source: :void
      )
    end
  end
end
