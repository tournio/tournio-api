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
#  index_stripe_products_on_purchasable_item_id  (purchasable_item_id)
#
require 'rails_helper'

RSpec.describe StripeProduct, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
