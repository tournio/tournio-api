module Stripe
  module Objects
    def create_price(currency:, product_id:, amount_in_dollars:, account_identifier:)
      Stripe::Price.create(
        {
          currency: currency,
          product: product_id,
          unit_amount: amount_in_dollars * 100,
        },
        {
          stripe_account: account_identifier,
        }
      )
    end
  end
end
