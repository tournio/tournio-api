# == Schema Information
#
# Table name: stripe_products
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  price_id            :string
#  product_id          :string
#  purchasable_item_id :bigint           not null
#
# Indexes
#
#  index_stripe_products_on_product_id_and_price_id  (product_id,price_id)
#  index_stripe_products_on_purchasable_item_id      (purchasable_item_id)
#
FactoryBot.define do
  factory :stripe_product do
    price_id { "stripe_price_#{SecureRandom.uuid}" }
    product_id { "stripe_product_#{SecureRandom.uuid}" }
    association :purchasable_item
  end
end
