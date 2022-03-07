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

  validate :valid_conditions?

  EARLY_REGISTRATION = 'early'
  REGULAR_REGISTRATION = 'regular'
  LATE_REGISTRATION = 'late'

  SUPPORTED_CONDITIONS = {
    registration_period: %w(early regular late),
  }.with_indifferent_access

  def self.defaultConditions
    {
      registration_period: REGULAR_REGISTRATION,
      # something like "full_shifts: []" might go here when we add support for multiple shifts...
    }
  end

  private

  def valid_conditions?
    my_keys = conditions.keys

    # look for extraneous conditions
    unless my_keys.intersection(SUPPORTED_CONDITIONS.keys).size == my_keys.size
      errors.add(:conditions, 'Unrecognized condition names found: ' + my_keys.difference(SUPPORTED_CONDITIONS.keys).join(', '))
    end

    # ensure that the value for each condition is one we recognize
    conditions.each_pair do |k, v|
      next unless SUPPORTED_CONDITIONS[k].present?
      unless SUPPORTED_CONDITIONS[k].include?(v)
        errors.add(:conditions, "Unsupported value #{v} found for condition #{k}")
      end
    end
  end
end
