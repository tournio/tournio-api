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
#  index_stripe_checkout_sessions_on_bowler_id  (bowler_id)
#
require 'rails_helper'

RSpec.describe StripeCheckoutSession, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
