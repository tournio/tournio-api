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
        payment_intent: "pi_test_#{SecureRandom.uuid}",
        customer_details: {
          email: 'contrived@address.org',
          name: 'Ephemer Elle',
        },
      }
    end
  end

  def real_checkout_session
    {
      "id": "cs_test_abc123xzt890",
      "object": "checkout.session",
      "after_expiration": nil,
      "allow_promotion_codes": nil,
      "amount_subtotal": 12000,
      "amount_total": 11000,
      "automatic_tax": {"enabled":false,"status":nil},
      "billing_address_collection": nil,
      "cancel_url": "http://localhost:3000/bowlers/12a43c83",
      "client_reference_id": nil,
      "client_secret": nil,
      "consent": nil,
      "consent_collection": nil,
      "created": 1702841434,
      "currency": "usd",
      "currency_conversion": nil,
      "custom_fields": [

      ],
      "custom_text": {"after_submit":nil,"shipping_address":nil,"submit":nil,"terms_of_service_acceptance":nil},
      "customer": nil,
      "customer_creation": "if_required",
      "customer_details": {"address":{"city":nil,"country":"US","line1":nil,"line2":nil,"postal_code":"76227","state":nil},"email":"example.person@example.com","name":"Example Person","phone":nil,"tax_exempt":"none","tax_ids":[]},
      "customer_email": nil,
      "expires_at": 1702927834,
      "invoice": nil,
      "invoice_creation": {"enabled":false,"invoice_data":{"account_tax_ids":nil,"custom_fields":nil,"description":nil,"footer":nil,"metadata":{},"rendering_options":nil}},
      "line_items": {
        "object":"list",
        "data":[{
          "id": "li_1OOQ2oIorUnGjsWjLbcn3gq6",
          "object": "item",
          "amount_discount": 1000,
          "amount_subtotal": 12000,
          "amount_tax": 0,
          "amount_total": 11000,
          "currency": "usd",
          "description": "Entry Fee",
          "discounts": [
            {
              "amount":1000,
              "discount":{
                "id":"di_1OOQ5yIorUnGjsWjufK93RdM",
                "object":"discount",
                "checkout_session":"cs_test_abc123xzt890",
                "coupon":{
                  "id":"PmiNeEIO",
                  "object":"coupon",
                  "amount_off":1000,
                  "created":1698710522,
                  "currency":"usd",
                  "duration":"once",
                  "duration_in_months":nil,
                  "livemode":true,
                  "max_redemptions":nil,
                  "metadata":{},
                  "name":"Early Registration Discount",
                  "percent_off":nil,
                  "redeem_by":nil,
                  "times_redeemed":50,
                  "valid":true
                },
                "customer":nil,
                "end":nil,
                "invoice":nil,
                "invoice_item":nil,
                "promotion_code":nil,
                "start":1702841630,
                "subscription":nil
              }
            }
          ],
          "price": {
            "id":"price_1O6QifIorUnGjsWjKZ03KPNd",
            "object":"price",
            "active":true,
            "billing_scheme":"per_unit",
            "created":1698554125,
            "currency":"usd",
            "custom_unit_amount":nil,
            "livemode":true,
            "lookup_key":nil,
            "metadata":{},
            "nickname":nil,
            "product":"prod_OuFDqBYJV0yny6",
            "recurring":nil,
            "tax_behavior":"unspecified",
            "tiers_mode":nil,
            "transform_quantity":nil,
            "type":"one_time",
            "unit_amount":12000,
            "unit_amount_decimal":"12000"
          },
          "quantity": 1
        }],
        "has_more":false,"url":"/v1/checkout/sessions/cs_test_abc123xzt890/line_items"},
      "livemode": true,
      "locale": nil,
      "metadata": {},
      "mode": "payment",
      "payment_intent": "pi_3OOQ5xIorUnGjsWj22KPJ0oF",
      "payment_link": nil,
      "payment_method_collection": "if_required",
      "payment_method_configuration_details": {"id":"pmc_1NtfL2IorUnGjsWjkk8zhTlT","parent":"pmc_1NOTDDIe5nsUMXFEAXkjW0kG"},
      "payment_method_options": {},
      "payment_method_types": [
        "card",
        "cashapp"
      ],
      "payment_status": "paid",
      "phone_number_collection": {"enabled":false},
      "recovered_from": nil,
      "setup_intent": nil,
      "shipping_address_collection": nil,
      "shipping_cost": nil,
      "shipping_details": nil,
      "shipping_options": [

      ],
      "status": "complete",
      "submit_type": "pay",
      "subscription": nil,
      "success_url": "http://localhost:3000/bowlers/12a43c83/finish_checkout",
      "total_details": {"amount_discount":1000,"amount_shipping":0,"amount_tax":0},
      "ui_mode": "hosted",
      "url": nil
    }
  end
end
