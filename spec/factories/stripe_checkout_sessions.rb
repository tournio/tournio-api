# == Schema Information
#
# Table name: stripe_checkout_sessions
#
#  id                  :bigint           not null, primary key
#  status              :integer          default("open")
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  bowler_id           :bigint           not null
#  checkout_session_id :string           not null
#
# Indexes
#
#  index_stripe_checkout_sessions_on_bowler_id            (bowler_id)
#  index_stripe_checkout_sessions_on_checkout_session_id  (checkout_session_id)
#
FactoryBot.define do
  factory :stripe_checkout_session do
    
  end
end
