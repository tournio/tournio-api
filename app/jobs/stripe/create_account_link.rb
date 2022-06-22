class CreateAccountLink
  include Sidekiq::Job

  def perform(stripe_account_identifier)
    acct = StripeAccount.find(stripe_account_identifier)
    result = Stripe::AccountLink.create(
      account: acct.identifier,
      refresh_url: 'TBD',
      return_url: 'TBD',
      type: 'account_onboarding',
    )
    acct.update(
      link_url: result.url,
      link_expires_at: Time.at(result.expires_at),
    )
  rescue ActiveRecord::NotFoundError
    Rails.logger.warn "Stripe account not found, identifier: #{stripe_account_identifier}"
  end
end
