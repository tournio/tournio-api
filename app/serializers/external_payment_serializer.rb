# frozen_string_literal: true

# == Schema Information
#
# Table name: external_payments
#
#  id            :bigint           not null, primary key
#  details       :jsonb
#  identifier    :string
#  payment_type  :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint
#
# Indexes
#
#  index_external_payments_on_identifier     (identifier)
#  index_external_payments_on_tournament_id  (tournament_id)
#

class ExternalPaymentSerializer < JsonSerializer
  attributes :identifier
end
