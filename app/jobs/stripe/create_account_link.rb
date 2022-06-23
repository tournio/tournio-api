module Stripe
  class CreateAccountLink
    include Sidekiq::Job

    attr_accessor :tournament_identifier

    def perform(stripe_account_identifier)
      acct = StripeAccount.includes(:tournament).find(stripe_account_identifier)
      self.tournament_identifier = acct.tournament.identifier
      result = Stripe::AccountLink.create(
        account: acct.identifier,
        refresh_url: "#{client_host}#{refresh_uri}",
        return_url: "#{client_host}#{return_uri}",
        type: 'account_onboarding',
      )
      acct.update(
        link_url: result.url,
        link_expires_at: Time.at(result.expires_at),
      )
    rescue ActiveRecord::NotFoundError
      Rails.logger.warn "Stripe account not found, identifier: #{stripe_account_identifier}"
    end

    def client_host
      Rails.env.production? ? 'https://www.igbo-reg.com' : 'http://localhost:3000'
    end

    def return_uri
      "/director/tournaments/#{tournament_identifier}/tbd"
    end

    def refresh_uri
      "/director/tournaments/#{tournament_identifier}/tbd"
    end
  end
end
