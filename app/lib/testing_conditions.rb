# frozen_string_literal: true

module TestingConditions
  def self.available_conditions
    {
      registration_period: {
        early: TestingEnvironment::EARLY_REGISTRATION,
        regular: TestingEnvironment::REGULAR_REGISTRATION,
        late: TestingEnvironment::LATE_REGISTRATION,
      },
    }
  end
end
