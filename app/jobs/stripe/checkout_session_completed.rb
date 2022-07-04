module Stripe
  class CheckoutSessionCompleted < EventHandler
    def handle_event
      Rails.logger.info "Handling the event my way!"

      # The checkout session is in event.data.object.
      # There should be line_items in there, indicating everything that was paid
      # for as part of the purchase, including quantities

      # Go through the line items in the event
      # Mark unpaid purchases as paid, create paid purchases for the rest, and create a ledger entry

      cs = Stripe::Checkout::Session.retrieve(
        {
          id: event[:data][:object][:id],
          expand: %w(line_items)
        },
        {
          stripe_account: event[:account],
        }
      )
      scp = StripeCheckoutSession.find_by(checkout_session_id: cs[:id])
      bowler = scp.bowler

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
        purchases = bowler.purchases.unpaid.where(purchasable_item: pi)
        if purchases.any?
          # quantity should be 1, since we don't create multiples of ledger items upon registration.
          # So, sanity check here.
          if purchases.count != quantity
            raise "We have a mismatched number of unpaid purchases. PItem ID: #{pi.identifier}. Stripe checkout session: #{cs[:id]}"
          end

          # Pick up here, when we have a model to associate it with.
          # purchases.update_all(paid_at: event[:created], )
        end

        # or is it a new purchase?
      end

    end
  end
end
