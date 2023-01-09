# == Schema Information
#
# Table name: stripe_payment_intents
#
#  id                         :bigint           not null, primary key
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
require 'rails_helper'

RSpec.describe StripePaymentIntent, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
