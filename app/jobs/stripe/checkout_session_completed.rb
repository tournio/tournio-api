module Stripe
  class CheckoutSessionCompleted < EventHandler
    attr_accessor :external_payment, :bowler, :paid_at

    def handle_event
      # The checkout session is in event.data.object.
      # There should be line_items in there, indicating everything that was paid
      # for as part of the purchase, including quantities

      # Go through the line items in the event
      # Mark unpaid purchases as paid, create paid purchases for the rest, and create a ledger entry

      cs = retrieve_stripe_object
      scp = StripeCheckoutSession.includes(bowler: :tournament).find_by(identifier: cs[:id])

      # Do we want to do anything when we're completed a checkout session that didn't originate with us?
      # Example: a fundraiser entry initiated from bigdclassic.com
      return unless scp.present?

      self.bowler = scp.bowler
      self.paid_at = Time.at(event[:created])
      self.external_payment = ExternalPayment.create(
        payment_type: :stripe,
        identifier: cs[:payment_intent],
        details: cs.to_hash,
        tournament: bowler.tournament
      )

      new_purchases = []
      # previous_paid_event_item_ids = bowler.purchases.event.paid.map { |p| p.purchasable_item.identifier }
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

        quantity.times do |_|
          new_purchases << Purchase.create(
            bowler: bowler,
            purchasable_item: pi,
            amount: pi.value,
            paid_at: paid_at,
            external_payment_id: external_payment.id
          )

          bowler.ledger_entries << LedgerEntry.new(
            debit: pi.value,
            source: :purchase,
            identifier: pi.name
          )
        end

        # mark any related Signups as paid
        signup = bowler.signups.find_by_purchasable_item_id(pi.id)
        if signup.present?
          signup.pay!

          # if it's a division item, disable the rest
          if pi.division?
            bowler.tournament.purchasable_items.division.where(name: pi.name).map do |div_pi|
              unless div_pi.id == pi.id
                bowler.signups.find_by_purchasable_item_id(div_pi.id).deactivate!
              end
            end
          end
        end

        # any discounts to apply, e.g., bundle discount for just-purchased events?
        if li[:discounts].present?
          li[:discounts].each { |d| handle_discount(d) }
        end
      end

      # A credit ledger entry for the total amount paid, as indicated by the payment provider
      bowler.ledger_entries << LedgerEntry.new(
        credit: cs[:amount_total] / 100, # (this comes in as cents, rather than dollars)
        source: :stripe,
        identifier: "Payment: #{cs[:payment_intent]}"
      )

      TournamentRegistration.notify_payment_contacts(
        bowler,
        external_payment.id,
        cs[:amount_total] / 100,
        event[:created]
      )

      scp.completed!
    end

    # At present, any discount may be applied only once per bowler.
    def handle_discount(discount)
      coupon_id = discount[:discount][:coupon][:id]
      sc = StripeCoupon.includes(:purchasable_item).find_by!(coupon_id: coupon_id)
      pi = sc.purchasable_item
      discounts_already_applied = bowler.purchases.paid.where(purchasable_item: pi)
      unless discounts_already_applied.any?
        bowler.purchases << Purchase.new(
          purchasable_item: pi,
          amount: pi.value,
          paid_at: paid_at,
          external_payment_id: external_payment.id
        )
        bowler.ledger_entries << LedgerEntry.new(
          credit: pi.value,
          source: :purchase,
          identifier: pi.name
        )
      end
    end

    def retrieve_stripe_object
      Stripe::Checkout::Session.retrieve(
        {
          id: event[:data][:object][:id],
          expand: %w(line_items.data.discounts)
        },
        {
          stripe_account: event[:account],
        }
      )
    end
  end
end
