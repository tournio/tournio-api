# == Schema Information
#
# Table name: stripe_accounts
#
#  identifier              :string           not null, primary key
#  link_expires_at         :datetime
#  link_url                :string
#  onboarding_completed_at :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  tournament_id           :integer
#  tournament_org_id       :bigint
#
# Indexes
#
#  index_stripe_accounts_on_tournament_id      (tournament_id)
#  index_stripe_accounts_on_tournament_org_id  (tournament_org_id)
#
class StripeAccount < ApplicationRecord
  belongs_to :tournament, optional: true
  belongs_to :tournament_org, optional: true

  def can_accept_payments?
    onboarding_completed_at.present?
  end
end
