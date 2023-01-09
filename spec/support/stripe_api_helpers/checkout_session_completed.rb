module StripeApiHelpers
  module CheckoutSessionCompleted
    def object_for_items(items_and_quantities)
      amount_total = 0
      line_items_data = []
      items_and_quantities.each do |iq|
        sp = iq[:item].stripe_product
        data = {
          quantity: iq[:quantity],
          price: {
            id: sp.price_id,
            product: sp.product_id,
          },
        }
        amount_total += iq[:item].value * iq[:quantity] * 100

        if iq[:discounts]
          discounts = []
          iq[:discounts].each do |d|
            discounts << {
              amount: d.value,
              discount: {
                coupon: {
                  id: d.stripe_coupon.coupon_id,
                },
              },
            }
            amount_total -= d.value * 100
          end
          data[:discounts] = discounts
        end

        line_items_data << data
      end
      {
        id: "cs_test_#{SecureRandom.uuid}",
        line_items: {
          data: line_items_data,
        },
        amount_total: amount_total,
        object: 'checkout.session',
        status: 'complete',
        payment_intent: "pi_test_#{SecureRandom.uuid}"
      }
    end
  end
end
