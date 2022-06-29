# == Schema Information
#
# Table name: stripe_accounts
#
#  id                      :bigint           not null, primary key
#  link_expires_at         :datetime
#  link_url                :string
#  onboarding_completed_at :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  tournament_id           :bigint           not null
#
# Indexes
#
#  index_stripe_accounts_on_tournament_id  (tournament_id)
#
require 'rails_helper'

RSpec.describe StripeAccount, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
