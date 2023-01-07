module Stripe
  class CouponCreator
    include Sidekiq::Job
    sidekiq_options retry: false

    attr_accessor :tournament,
      :stripe_account,
      :purchasable_item,
      :coupon

    def perform(purchasable_item_id)
      set_attributes(purchasable_item_id)

      create_coupon

      purchasable_item.stripe_coupon = StripeCoupon.new(coupon_id: coupon[:id])
    rescue StripeError => e
      Rails.logger.warn "Failed to associate PurchasableItem with Stripe Coupon: #{e.message}"
    end

    def set_attributes(purchasable_item_id)
      self.purchasable_item = PurchasableItem.includes(tournament: :stripe_account).find(purchasable_item_id)
      self.tournament = purchasable_item.tournament
      self.stripe_account = tournament.stripe_account
    end

    def create_coupon
      # - amount_off – positive integer – amount that'll be removed from the total
      # - currency – the 3-letter ISO code (e.g., 'usd')
      # - name – name of the coupon to display to the customer
      # - redeem_by – Unix timestamp representing the "valid_until" time, after which the coupon cannot be redeemed.
      # - applies_to – optional hash giving directions for what it applies to.
      #   - products – array of Product IDs. If we use ethis, it'll be the ID of the entry-fee Product

      coupon_hash = {
        name: purchasable_item.name,
        amount_off: purchasable_item.value * 100,
        currency: tournament.currency,
        
        # Don't include redeem by; this blocks the Stripe transaction if that timestamp has passed.
        # If the discount is still there after its expiration time, that's on us (or on the tournament),
        # and should not block the bowler from paying.
        #
        # redeem_by: Time.parse(purchasable_item.configuration['valid_until']).to_i,
      }

      self.coupon = Stripe::Coupon.create(
        coupon_hash,
        {
          stripe_account: stripe_account.identifier,
        }
      )
    end
  end
end
