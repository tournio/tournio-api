module StripeApiHelpers
  module CheckoutSessionCompleted
    def object_for_items(items_and_quantities)
      amount_total = 0
      line_items_data = []
      applied_discounts = {}

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
            unless applied_discounts[d.stripe_coupon.coupon_id].present?
              amount_total -= d.value * 100
              applied_discounts[d.stripe_coupon.coupon_id] = true
            end
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

    # example = {
    #   "id" => "cs_live_b1dfnDQ0g341xqNCtzict6GIVgFBhXgUAHWWm6CC6ALBK3mvk67nuv3Cwj",
    #   "url" => nil,
    #   "mode" => "payment",
    #   "locale" => nil,
    #   "object" => "checkout.session",
    #   "status" => "complete",
    #   "consent" => nil,
    #   "created" => 1691276120,
    #   "invoice" => nil,
    #   "currency" => "usd",
    #   "customer" => nil,
    #   "livemode" => true,
    #   "metadata" => {},
    #   "cancel_url" => "https://www.tourn.io/bowlers/26b7a043-29b0-4a8f-b1dd-19a1e093c56a",
    #   "expires_at" => 1691362519,
    #   "line_items" =>
    #     {
    #       "url" => "/v1/checkout/sessions/cs_live_b1dfnDQ0g341xqNCtzict6GIVgFBhXgUAHWWm6CC6ALBK3mvk67nuv3Cwj/line_items",
    #       "data" =>
    #         [
    #           {
    #             "id" => "li_1NbtNTICVv1lvAhFLszVYUKR",
    #             "price" =>
    #               {
    #                 "id" => "price_1NS2tbICVv1lvAhFAMPNd8Vx",
    #                 "type" => "one_time",
    #                 "active" => true,
    #                 "object" => "price",
    #                 "created" => 1688929427,
    #                 "product" => "prod_OEVvVUjIPP4y49",
    #                 "currency" => "usd",
    #                 "livemode" => true,
    #                 "metadata" => {},
    #                 "nickname" => nil,
    #                 "recurring" => nil,
    #                 "lookup_key" => nil,
    #                 "tiers_mode" => nil,
    #                 "unit_amount" => 8500,
    #                 "tax_behavior" => "unspecified",
    #                 "billing_scheme" => "per_unit",
    #                 "custom_unit_amount" => nil,
    #                 "transform_quantity" => nil,
    #                 "unit_amount_decimal" => "8500"
    #               },
    #             "object" => "item",
    #             "currency" => "usd",
    #             "quantity" => 1,
    #             "discounts" =>
    #               [
    #                 {
    #                   "amount" => 1250,
    #                   "discount" =>
    #                     {
    #                       "id" => "di_1NbtPbICVv1lvAhFvlufoUKW",
    #                       "end" => nil,
    #                       "start" => 1691276251,
    #                       "coupon" =>
    #                         {
    #                           "id" => "fyTM1jgF",
    #                           "name" => "DAMIT Bundle Discount",
    #                           "valid" => true,
    #                           "object" => "coupon",
    #                           "created" => 1688929475,
    #                           "currency" => "usd",
    #                           "duration" => "once",
    #                           "livemode" => true,
    #                           "metadata" => {},
    #                           "redeem_by" => nil,
    #                           "amount_off" => 2500,
    #                           "percent_off" => nil,
    #                           "times_redeemed" => 3,
    #                           "max_redemptions" => nil,
    #                           "duration_in_months" => nil
    #                         },
    #                       "object" => "discount",
    #                       "invoice" => nil,
    #                       "customer" => nil,
    #                       "invoice_item" => nil,
    #                       "subscription" => nil,
    #                       "promotion_code" => nil,
    #                       "checkout_session" => "cs_live_b1dfnDQ0g341xqNCtzict6GIVgFBhXgUAHWWm6CC6ALBK3mvk67nuv3Cwj"
    #                     }
    #                 }
    #               ],
    #             "amount_tax" => 0,
    #             "description" => "Singles",
    #             "amount_total" => 7250,
    #             "amount_discount" => 1250,
    #             "amount_subtotal" => 8500
    #           },
    #           {
    #             "id" => "li_1NbtNTICVv1lvAhFMN5J5YP4",
    #             "price" =>
    #               {
    #                 "id" => "price_1NS2tsICVv1lvAhFxnsyI0IZ",
    #                 "type" => "one_time",
    #                 "active" => true,
    #                 "object" => "price",
    #                 "created" => 1688929444,
    #                 "product" => "prod_OEVv9Te2YgUXRw",
    #                 "currency" => "usd",
    #                 "livemode" => true,
    #                 "metadata" => {},
    #                 "nickname" => nil,
    #                 "recurring" => nil,
    #                 "lookup_key" => nil,
    #                 "tiers_mode" => nil,
    #                 "unit_amount" => 8500,
    #                 "tax_behavior" => "unspecified",
    #                 "billing_scheme" => "per_unit",
    #                 "custom_unit_amount" => nil,
    #                 "transform_quantity" => nil,
    #                 "unit_amount_decimal" => "8500"
    #               },
    #             "object" => "item",
    #             "currency" => "usd",
    #             "quantity" => 1,
    #             "discounts" =>
    #               [
    #                 {
    #                   "amount" => 1250,
    #                   "discount" =>
    #                     {
    #                       "id" => "di_1NbtPbICVv1lvAhFvlufoUKW",
    #                       "end" => nil,
    #                       "start" => 1691276251,
    #                       "coupon" =>
    #                         {
    #                           "id" => "fyTM1jgF",
    #                           "name" => "DAMIT Bundle Discount",
    #                           "valid" => true,
    #                           "object" => "coupon",
    #                           "created" => 1688929475,
    #                           "currency" => "usd",
    #                           "duration" => "once",
    #                           "livemode" => true,
    #                           "metadata" => {},
    #                           "redeem_by" => nil,
    #                           "amount_off" => 2500,
    #                           "percent_off" => nil,
    #                           "times_redeemed" => 3,
    #                           "max_redemptions" => nil,
    #                           "duration_in_months" => nil
    #                         },
    #                       "object" => "discount",
    #                       "invoice" => nil,
    #                       "customer" => nil,
    #                       "invoice_item" => nil,
    #                       "subscription" => nil,
    #                       "promotion_code" => nil,
    #                       "checkout_session" => "cs_live_b1dfnDQ0g341xqNCtzict6GIVgFBhXgUAHWWm6CC6ALBK3mvk67nuv3Cwj"
    #                     }
    #                 }
    #               ],
    #             "amount_tax" => 0,
    #             "description" => "Baker Doubles",
    #             "amount_total" => 7250,
    #             "amount_discount" => 1250,
    #             "amount_subtotal" => 8500
    #           }
    #         ],
    #       "object" => "list",
    #       "has_more" => false
    #     },
    #   "custom_text" => { "submit" => nil, "shipping_address" => nil },
    #   "submit_type" => "pay",
    #   "success_url" => "https://www.tourn.io/bowlers/26b7a043-29b0-4a8f-b1dd-19a1e093c56a/finish_checkout",
    #   "amount_total" => 14500,
    #   "payment_link" => nil,
    #   "setup_intent" => nil,
    #   "subscription" => nil,
    #   "automatic_tax" => { "status" => nil, "enabled" => false },
    #   "custom_fields" => [],
    #   "shipping_cost" => nil,
    #   "total_details" => { "amount_tax" => 0, "amount_discount" => 2500, "amount_shipping" => 0 },
    #   "customer_email" => nil,
    #   "payment_intent" => "pi_3NbtPbICVv1lvAhF06wi8rcP",
    #   "payment_status" => "paid",
    #   "recovered_from" => nil,
    #   "amount_subtotal" => 17000,
    #   "after_expiration" => nil,
    #   "customer_details" =>
    #     {
    #       "name" => "Timothy S Rice",
    #       "email" => "tsrice3@aol.com",
    #       "phone" => nil,
    #       "address" => { "city" => nil, "line1" => nil, "line2" => nil, "state" => nil, "country" => "US", "postal_code" => "76005" },
    #       "tax_ids" => [],
    #       "tax_exempt" => "none"
    #     },
    #   "invoice_creation" => { "enabled" => false, "invoice_data" => { "footer" => nil, "metadata" => {}, "description" => nil, "custom_fields" => nil, "account_tax_ids" => nil, "rendering_options" => nil } },
    #   "shipping_details" => nil,
    #   "shipping_options" => [],
    #   "customer_creation" => "if_required",
    #   "consent_collection" => nil,
    #   "client_reference_id" => nil,
    #   "currency_conversion" => nil,
    #   "payment_method_types" => ["card", "cashapp"],
    #   "allow_promotion_codes" => nil,
    #   "payment_method_options" => {},
    #   "phone_number_collection" => { "enabled" => false
    #   },
    #   "payment_method_collection" => "always",
    #   "billing_address_collection" => nil,
    #   "shipping_address_collection" => nil
    # }

  end
end
