module Stripe
  class CheckoutSessionExpired < EventHandler

    def handle_event
      # The checkout session is in event.data.object.
      # But we don't care, since we don't need to update or create anything.

      cs = retrieve_stripe_object
      scp = StripeCheckoutSession.find_by(identifier: cs[:id])

      # Do we want to do anything when we're completed a checkout session that didn't originate with us?
      # Example: a fundraiser entry initiated from bigdclassic.com
      return unless scp.present?

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
