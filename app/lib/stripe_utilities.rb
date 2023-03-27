module StripeUtilities
  attr_accessor :tournament, :stripe_account

  def load_stripe_account
    self.stripe_account = tournament.stripe_account
  end

  def client_host
    Rails.env.production? ? 'https://www.tourn.io' : 'http://localhost:3000'
  end

  # assumes the existence of tournament
  def return_uri
    "/director/tournaments/#{tournament.identifier}?stripe=true"
  end

  # assumes the existence of tournament
  def refresh_uri
    "/director/tournaments/#{tournament.identifier}/stripe_account_setup"
  end

  # assumes the existence of tournament
  def create_stripe_account
    result = Stripe::Account.create(
      type: Rails.env.production? ? 'standard' : 'express',
      business_type: 'non_profit'
    )
    Rails.logger.debug "Stripe account creation result: #{result.inspect}"
    StripeAccount.create(tournament_id: tournament.id, identifier: result.id)
  rescue Stripe::StripeError => e
    Rails.logger.info "Stripe error: #{e}"
    Bugsnag.notify(e)
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
  rescue Stripe::StripeError => e
    Rails.logger.info "Stripe error: #{e}"
    Bugsnag.notify(e)
  end

  # assumes the existence of stripe_account
  def get_account_details
    Stripe::Account.retrieve(stripe_account.identifier)
  rescue Stripe::StripeError => e
    Rails.logger.info "Stripe error: #{e}"
    Bugsnag.notify(e)
  end

  # assumes the existence of stripe_account
  #
  # account_obj is a Stripe::Account instance
  def update_account_details(account_obj)
    charges_enabled = account_obj[:charges_enabled]
    info_submitted = account_obj[:details_submitted]

    # Did they complete the onboarding process, and can now make charges?
    unless stripe_account.onboarding_completed_at.present?
      stripe_account.update(onboarding_completed_at: Time.zone.now) if charges_enabled && info_submitted

      # look for any PurchasableItems without associated Stripe products and create them
      create_stripe_products
    end

    # What if the account was disabled / deactivated?
    unless charges_enabled && info_submitted && stripe_account.onboarding_completed_at.present?
      stripe_account.update(onboarding_completed_at: nil)
    end
  end

  def line_item_for_purchasable_item(pi, quantity = 1)
    stripe_product = pi.stripe_product
    {
      quantity: quantity,
      price: stripe_product.price_id,
    }
  end

  def discount_for_purchasable_item(pi)
    stripe_coupon = pi.stripe_coupon
    {
      coupon: stripe_coupon.coupon_id,
    }
  end

  def create_stripe_products
    tournament.purchasable_items.bowling.where(stripe_product: nil).each do |pi|
      Stripe::ProductCreator.perform_in(Rails.configuration.sidekiq_async_delay, pi.id)
    end
  end
end
