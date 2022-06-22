# == Schema Information
#
# Table name: stripe_accounts
#
#  id                      :bigint           not null, primary key
#  onboarding_completed_at :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  tournament_id           :bigint           not null
#
# Indexes
#
#  index_stripe_accounts_on_tournament_id  (tournament_id)
#
class StripeAccount < ApplicationRecord
end
