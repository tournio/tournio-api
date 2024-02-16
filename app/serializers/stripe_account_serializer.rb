# frozen_string_literal: true

class StripeAccountSerializer < JsonSerializer
  attributes :identifier,
    :onboarding_completed_at
end
