# frozen_string_literal: true

class VoidPurchaseJob
  include Sidekiq::Job

  def perform(purchase_id, why)
    p = Purchase.find(purchase_id)
    unless p.paid_at.present?
      p.update(voided_at: Time.zone.now, void_reason: why)

      # If the voided purchase was a discount, then create this as a debit
      # Otherwise, create it as a credit (voiding a purchase).
      credit = 0
      debit = 0
      if %w(early_discount bundle_discount).include?(p.determination)
        debit = p.amount
      else
        credit = p.amount
      end
      p.bowler.ledger_entries << LedgerEntry.new(
        debit: debit,
        credit: credit,
        identifier: "[voided] #{p.name}",
        notes: why,
        source: :void
      )
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.info "Could not find purchase with id=#{purchase_id}. Maybe it was already voided?"
  end
end
