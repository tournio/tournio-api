# frozen_string_literal: true

#  details       :jsonb
#  identifier    :string
#  payment_type  :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint

class ExternalPaymentSerializer < JsonSerializer
  attributes :identifier
end
