module Stripe
  class ProductUpdater
    include Sidekiq::Job
    include Stripe::Objects

    sidekiq_options retry: false

    attr_accessor :tournament,
      :stripe_account,
      :purchasable_item,
      :stripe_product

    def perform(purchasable_item_id)
      set_attributes(purchasable_item_id)

      deactivate_price(
        price_id: stripe_product.price_id,
        account_identifier: stripe_account.identifier
      )

      price = create_price(
        currency: tournament.currency,
        product_id: stripe_product.product_id,
        amount_in_dollars: purchasable_item.value,
        account_identifier: stripe_account.identifier
      )

      stripe_product.update(price_id: price[:id])
    rescue StripeError => e
      Bugsnag.notify(e)
      Rails.logger.warn "Failed to update PurchasableItem with Stripe Product or Price: #{e.message}"
    end

    def set_attributes(purchasable_item_id)
      self.purchasable_item = PurchasableItem.includes(tournament: :stripe_account).find(purchasable_item_id)
      self.tournament = purchasable_item.tournament
      self.stripe_account = tournament.stripe_account
      self.stripe_product = purchasable_item.stripe_product
    end
  end
end
