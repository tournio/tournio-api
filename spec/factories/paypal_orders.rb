# == Schema Information
#
# Table name: paypal_orders
#
#  id         :bigint           not null, primary key
#  details    :jsonb
#  identifier :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :paypal_order do
    # t.string "identifier"
    # t.jsonb "details"
    # t.datetime "created_at", precision: 6, null: false
    # t.datetime "updated_at", precision: 6, null: false

    identifier { SecureRandom.uuid }
    details { {} }
  end
end
