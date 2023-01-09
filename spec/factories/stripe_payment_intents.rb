# == Schema Information
#
# Table name: stripe_payment_intents
#
#  id                         :bigint           not null, primary key
#  amount_received            :integer          default(0)
#  identifier                 :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  stripe_checkout_session_id :bigint           not null
#
# Indexes
#
#  index_stripe_payment_intents_on_identifier                  (identifier)
#  index_stripe_payment_intents_on_stripe_checkout_session_id  (stripe_checkout_session_id)
#
FactoryBot.define do
  factory :stripe_payment_intent do
    
  end
end
