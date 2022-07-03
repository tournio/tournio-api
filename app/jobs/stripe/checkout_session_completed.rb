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

      line_items = cs[:line_items][:data]
      # inside each line_item is a price object, which has the important things:
      # - id (of Price object)
      # - product (id of Product object)


      Rails.logger.info "Checkout session retrieved: #{cs.inspect}"
    end
  end
end
