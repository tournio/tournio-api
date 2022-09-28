module Stripe
  class AccountUpdated < EventHandler
    include StripeUtilities

    def handle_event
      self.stripe_account = StripeAccount.find(event[:account])
      account_obj = get_account_details
      update_account_details(account_obj)
    end
  end
end
