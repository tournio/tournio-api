module Stripe
  class CouponDestroyer
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(stripe_coupon_identifier, stripe_account_identifier)
      Stripe::Coupon.delete(
        stripe_coupon_identifier,
        {},
        {
          stripe_account: stripe_account_identifier,
        }
      )
    rescue StripeError => e
      Rails.logger.warn "Failed to delete Stripe Coupon: #{e.message}"
    end
  end
end
