module Stripe
  class ProductCreator
    include Sidekiq::Job
    sidekiq_options retry: false

    attr_accessor :tournament,
      :stripe_account,
      :purchasable_item,
      :product,
      :price

    def perform(purchasable_item_id)
      set_attributes(purchasable_item_id)

      create_product
      create_price

      purchasable_item.stripe_product = StripeProduct.new(product_id: product[:id], price_id: price[:id])
    rescue StripeError => e
      Rails.logger.warn "Failed to associate PurchasableItem with Stripe Product or Price: #{e.message}"
    end

    def set_attributes(purchasable_item_id)
      self.purchasable_item = PurchasableItem.includes(tournament: :stripe_account).find(purchasable_item_id)
      self.tournament = purchasable_item.tournament
      self.stripe_account = tournament.stripe_account
    end

    def create_product
      product_hash = {
        name: purchasable_item.name,
      }
      product_hash[:description] = division_description if purchasable_item.division?
      product_hash[:description] = banquet_description if purchasable_item.banquet?
      self.product = Stripe::Product.create(
        product_hash,
        {
          stripe_account: stripe_account.identifier,
        }
      )
    end

    def create_price
      self.price = Stripe::Price.create(
        {
          currency: tournament.currency,
          product: product[:id],
          unit_amount: purchasable_item.value * 100,
        },
        {
          stripe_account: stripe_account.identifier,
        }
      )
    end

    def division_description
      desc = purchasable_item.configuration['division']
      if purchasable_item.configuration['note'].present?
        desc += " (#{purchasable_item.configuration['note']})"
      end
      desc
    end

    def banquet_description
      purchasable_item.configuration['note']
    end

    # Also to do:
    # - product
    # - late fee
    #
    # Coupons:
    # - early discount
    # - bundle discount
  end
end
