module Stripe
  class ChargeRefunded < EventHandler

    def handle_event
      cs = retrieve_stripe_object
      scp = StripeCheckoutSession.find_by(identifier: cs[:id])

      # TODO: any sanity-checking, e.g.,
      #  - in the event the SCP model shows it was anything but open

      scp.expired!
    end

    def retrieve_stripe_object
      Stripe::Checkout::Session.retrieve(
        {
          id: event[:data][:object][:id],
        },
        {
          stripe_account: event[:account],
        }
      )
    end
  end
end
