module StripeUtilities
  attr_accessor :tournament, :stripe_account

  def client_host
    Rails.env.production? ? 'https://www.igbo-reg.com' : 'http://localhost:3000'
  end

  # assumes the existence of tournament
  def return_uri
    "/director/tournaments/#{tournament.identifier}/tbd"
  end

  # assumes the existence of tournament
  def refresh_uri
    "/director/tournaments/#{tournament.identifier}/tbd"
  end

  # assumes the existence of tournament
  def create_stripe_account
    result = Stripe::Account.create(
      type: 'standard',
      business_type: 'non_profit'
    )
    Rails.logger.debug "Stripe account creation result: #{result.inspect}"
    unless result.instance_of?(StripeError)
      StripeAccount.create(tournament_id: tournament.id, identifier: result.id)
    end
  end

  # assumes the existence of stripe_account
  def get_updated_account_link
    result = Stripe::AccountLink.create(
      account: stripe_account.identifier,
      refresh_url: "#{client_host}#{refresh_uri}",
      return_url: "#{client_host}#{return_uri}",
      type: 'account_onboarding',
    )
    stripe_account.update(
      link_url: result.url,
      link_expires_at: Time.at(result.expires_at),
    )
  end
end
