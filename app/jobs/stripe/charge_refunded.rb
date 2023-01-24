module Stripe
  class ChargeRefunded < EventHandler

    def handle_event
      charge = event[:data][:object]
      payment_intent_identifier = charge[:payment_intent]
      credit_ledger_entry = LedgerEntry.find_by!(identifier: payment_intent_identifier)
      bowler_id = credit_ledger_entry.bowler_id
      LedgerEntry.create(
        bowler_id: bowler_id,
        debit: charge[:amount_refunded] / 100,
        identifier: charge[:id],
        source: :stripe
      ) unless LedgerEntry.exists?(identifier: charge[:id])

    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn "Received charge.refunded with unrecognized PaymentIntent identifier: #{payment_intent_identifier}"
    end
  end
end
