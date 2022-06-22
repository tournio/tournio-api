class CreateAccount
  include Sidekiq::Job

  def perform(tournament_id)
    result = Stripe::Account.create(
      type: 'standard',
      business_type: 'non_profit'
    )
    Rails.logger.debug "Stripe account creation result: #{result.inspect}"
    StripeAccount.create(tournament_id: tournament_id, identifier: result.id)
  end
end
