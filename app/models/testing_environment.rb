# == Schema Information
#
# Table name: testing_environments
#
#  id            :bigint           not null, primary key
#  conditions    :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_testing_environments_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (tournament_id => tournaments.id)
#
class TestingEnvironment < ApplicationRecord
  belongs_to :tournament

  EARLY_REGISTRATION = 'early'
  REGULAR_REGISTRATION = 'regular'
  LATE_REGISTRATION = 'late'

  def self.defaultConditions
    {
      registration_period: REGULAR_REGISTRATION,
      # something like "full_shifts: []" might go here when we add support for multiple shifts...
    }
  end
end
