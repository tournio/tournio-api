# == Schema Information
#
# Table name: stripe_events
#
#  id               :bigint           not null, primary key
#  event_identifier :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_stripe_events_on_event_identifier  (event_identifier)
#
require 'rails_helper'

RSpec.describe StripeEvent, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
