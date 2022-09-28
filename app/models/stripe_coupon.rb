# == Schema Information
#
# Table name: stripe_coupons
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  coupon_id           :string
#  purchasable_item_id :bigint           not null
#
# Indexes
#
#  index_stripe_coupons_on_coupon_id            (coupon_id)
#  index_stripe_coupons_on_purchasable_item_id  (purchasable_item_id)
#
class StripeCoupon < ApplicationRecord
  belongs_to :purchasable_item
end
