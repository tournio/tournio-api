# == Schema Information
#
# Table name: purchases
#
#  id                  :bigint           not null, primary key
#  amount              :integer          default(0)
#  identifier          :string           not null
#  paid_at             :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  bowler_id           :bigint
#  paypal_order_id     :bigint
#  purchasable_item_id :bigint
#
# Indexes
#
#  index_purchases_on_bowler_id            (bowler_id)
#  index_purchases_on_identifier           (identifier)
#  index_purchases_on_paypal_order_id      (paypal_order_id)
#  index_purchases_on_purchasable_item_id  (purchasable_item_id)
#
FactoryBot.define do
  factory :purchase do
    # t.string "identifier", null: false
    # t.bigint "bowler_id"
    # t.bigint "purchasable_item_id"
    # t.integer "amount", default: 0
    # t.datetime "paid_at"

    identifier { SecureRandom.uuid }
    amount { 19 }

    association :purchasable_item, strategy: :create
    association :bowler, strategy: :create
  end

  trait :paid do
    paid_at { Time.zone.now }
  end
end
