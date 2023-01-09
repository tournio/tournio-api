# == Schema Information
#
# Table name: stripe_checkout_sessions
#
#  id                        :bigint           not null, primary key
#  identifier                :string           not null
#  payment_intent_identifier :string
#  status                    :integer          default("open")
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  bowler_id                 :bigint           not null
#
# Indexes
#
#  index_stripe_checkout_sessions_on_bowler_id                  (bowler_id)
#  index_stripe_checkout_sessions_on_identifier                 (identifier)
#  index_stripe_checkout_sessions_on_payment_intent_identifier  (payment_intent_identifier)
#
class StripeCheckoutSession < ApplicationRecord
  belongs_to :bowler

  enum :status, %i(open completed expired)
end
