module Stripe
  class ProductDeactivator
    include Sidekiq::Job
    include Stripe::Objects
    sidekiq_options retry: false

    def perform(stripe_product_id, stripe_account_identifier)
      sp = StripeProduct.find(stripe_product_id)

      # Stripe won't actually let us delete a Product if it has a Price associated with it, so the best we can do
      # is deactivate both the Price and the product

      deactivate_price(
        price_id: sp.price_id,
        account_identifier: stripe_account_identifier
      )

      Stripe::Product.update(
        sp.product_id,
        {
          active: false,
        },
        {
          stripe_account: stripe_account_identifier,
        }
      )
    rescue StripeError => e
      Rails.logger.warn "Failed to deactivate Stripe Product: #{e.message}"
    end
  end
end
