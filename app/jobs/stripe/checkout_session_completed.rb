module Stripe
  class CheckoutSessionCompleted < EventHandler
    def handle_event
      Rails.logger.info "Handling the event my way!"

      # The checkout session is in event.data.object.
      # There should be line_items in there, indicating everything that was paid
      # for as part of the purchase, including quantities


    end
  end
end
