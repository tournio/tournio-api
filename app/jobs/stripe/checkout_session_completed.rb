module Stripe
  class CheckoutSessionCompleted < EventHandler
    def handle_event
      # The checkout session is in event.data.object.
      # There should be line_items in there, indicating everything that was paid
      # for as part of the purchase, including quantities

      # Go through the line items in the event
      # Mark unpaid purchases as paid, create paid purchases for the rest, and create a ledger entry

      # TODO:
      #  - early-registration discounts
      #  - event bundle discounts
      #  - event-linked late fees

      cs = Stripe::Checkout::Session.retrieve(
        {
          id: event[:data][:object][:id],
          expand: %w(line_items)
        },
        {
          stripe_account: event[:account],
        }
      )
      external_payment = ExternalPayment.create(payment_type: :stripe, identifier: cs[:id], details: cs.to_hash)
      scp = StripeCheckoutSession.find_by(checkout_session_id: cs[:id])
      bowler = scp.bowler

      # TODO:
      #  - any sanity-checking, in the event the SCP model shows it was already completed

      new_purchases = []
      # previous_paid_event_item_ids = bowler.purchases.event.paid.map { |p| p.purchasable_item.identifier }
      total_credit = 0
      line_items = cs[:line_items][:data]
      # inside each line_item is a price object, which has the important things:
      # - id (of Price object)
      # - product (id of Product object)
      line_items.each do |li|
        price_id = li[:price][:id]
        product_id = li[:price][:product]
        quantity = li[:quantity]
        sp = StripeProduct.includes(purchasable_item: :tournament).find_by(price_id: price_id, product_id: product_id)
        pi = sp.purchasable_item

        # does the pi correspond to an unpaid purchase?
        unpaid_purchases = bowler.purchases.unpaid.where(purchasable_item: pi)
        if unpaid_purchases.any?
          # quantity should be 1, since we don't create multiples of ledger items upon registration.
          # So, sanity check here.
          if unpaid_purchases.count != quantity
            raise "We have a mismatched number of unpaid purchases. PItem ID: #{pi.identifier}. Stripe checkout session: #{cs[:id]}"
          end

          unpaid_purchases.update_all(
            paid_at: event[:created],
            external_payment: external_payment
          )
          quantity.times do |_|
            bowler.ledger_entries << LedgerEntry.new(
              debit: pi.value,
              source: :purchase,
              identifier: pi.name
            )
          end
        else
          # or is it a new purchase?
          quantity.times do |_|
            new_purchases << Purchase.create(
              bowler: bowler,
              purchasable_item: pi,
              amount: pi.value,
              paid_at: event[:created],
              external_payment: external_payment
            )

            bowler.ledger_entries << LedgerEntry.new(
              debit: pi.value,
              source: :purchase,
              identifier: pi.name
            )
            total_credit += pi.value
          end
        end
      end

      unless total_credit == 0
        bowler.ledger_entries << LedgerEntry.new(
          credit: total_credit,
          source: :stripe,
          identifier: cs[:id]
        )
      end

      TournamentRegistration.send_receipt_email(bowler, external_payment.identifier)
      TournamentRegistration.try_confirming_bowler_shift(bowler)
      scp.completed!
    end
  end
end
