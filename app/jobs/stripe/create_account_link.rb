module Stripe
  class CreateAccountLink
    include Sidekiq::Job
    include StripeUtilities

    def perform(tournament_identifier)
      self.tournament = Tournament.includes(:stripe_account).find(tournament_identifier)
      self.stripe_account = tournament.stripe_account

      get_updated_account_link
    rescue ActiveRecord::NotFoundError
      Rails.logger.warn "Stripe account not found, identifier: #{stripe_account_identifier}"
    end
  end
end
