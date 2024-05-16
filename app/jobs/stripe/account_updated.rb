module Stripe
  class AccountUpdated < EventHandler
    include StripeUtilities

    def handle_event
      self.stripe_account = StripeAccount.find(event[:account])
      self.tournament_org = stripe_account.tournament_org
      account_obj = get_account_details
      update_account_details(account_obj)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn "Received AccountUpdated event for unrecognized account: #{event[:account]}"
    end
  end
end
