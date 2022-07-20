module Stripe
  class CheckoutSessionCompleted < EventHandler
    attr_accessor :external_payment, :bowler, :paid_at

    def handle_event
      # The checkout session is in event.data.object.
      # There should be line_items in there, indicating everything that was paid
      # for as part of the purchase, including quantities

      # Go through the line items in the event
      # Mark unpaid purchases as paid, create paid purchases for the rest, and create a ledger entry

      # TODO:
      #  - event-linked late fees (maybe we don't need to?)

      cs = retrieve_stripe_object
      self.external_payment = ExternalPayment.create(payment_type: :stripe, identifier: cs[:id], details: cs.to_hash)
      scp = StripeCheckoutSession.find_by(identifier: cs[:id])
      self.bowler = scp.bowler
      self.paid_at = Time.at(event[:created])

      # TODO: any sanity-checking, e.g.,
      #  - in the event the SCP model shows it was already completed
      #  - verifying that the amount of each line item matches the value of the PurchasableItem

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
            paid_at: paid_at,
            external_payment_id: external_payment.id
          )
          total_credit += pi.value * quantity

          # Is there a coupon associated?
          # Right now, all discounts on our side are created as unpaid purchases,
          # so it is not possible for one to be associated with a new purchase.
          if li[:discounts].present?
            li[:discounts].each { |d| total_credit -= handle_discount(d) }
          end
        else
          # or is it a new purchase?
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

    def handle_discount(discount)
      coupon_id = discount[:discount][:coupon][:id]
      sc = StripeCoupon.includes(:purchasable_item).find_by!(coupon_id: coupon_id)
      pi = sc.purchasable_item
      purchase = bowler.purchases.unpaid.where(purchasable_item: pi).first
      purchase.update(
        paid_at: paid_at,
        external_payment_id: external_payment.id
      )
      pi.value
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
