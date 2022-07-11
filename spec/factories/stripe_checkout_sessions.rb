# == Schema Information
#
# Table name: stripe_checkout_sessions
#
#  id         :bigint           not null, primary key
#  identifier :string           not null
#  status     :integer          default("open")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  bowler_id  :bigint           not null
#
# Indexes
#
#  index_stripe_checkout_sessions_on_bowler_id   (bowler_id)
#  index_stripe_checkout_sessions_on_identifier  (identifier)
#
FactoryBot.define do
  factory :stripe_checkout_session do
    identifier { "stripe_checkout_session_#{SecureRandom.uuid}" }

    trait :completed do
      status { 'completed' }
    end
  end
end
