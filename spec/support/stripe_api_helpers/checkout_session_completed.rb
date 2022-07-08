module StripeApiHelpers
  module CheckoutSessionCompleted
    def object_for_items(items_and_quantities)
      line_items_data = []
      items_and_quantities.each do |iq|
        sp = iq[:item].stripe_product
        line_items_data << {
          quantity: iq[:quantity],
          price: {
            id: sp.price_id,
            product: sp.product_id,
          },
        }
      end
      {
        id: "cs_test_#{SecureRandom.uuid}",
        line_items: {
          data: line_items_data,
        },
        object: 'checkout.session',
        status: 'complete',
      }
    end
  end
end
