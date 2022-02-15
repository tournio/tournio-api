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
FactoryBot.define do
  factory :testing_environment do
    tournament { nil }
    conditions do
      {
        registration_period: TestingEnvironment::REGULAR_REGISTRATION,
      }
    end
  end
end
