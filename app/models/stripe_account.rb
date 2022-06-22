# == Schema Information
#
# Table name: stripe_accounts
#
#  identifier              :string           not null, primary key
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
  #
  # The identifier column is the Stripe account ID
  #

  belongs_to :tournament

  def can_accept_payments?
    onboarding_completed_at.present?
  end
end
