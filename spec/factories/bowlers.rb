# frozen_string_literal: true

# == Schema Information
#
# Table name: bowlers
#
#  id                 :bigint           not null, primary key
#  identifier         :string
#  position           :integer
#  verified_data      :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  doubles_partner_id :bigint
#  person_id          :bigint
#  team_id            :bigint
#  tournament_id      :bigint
#
# Indexes
#
#  index_bowlers_on_created_at          (created_at)
#  index_bowlers_on_doubles_partner_id  (doubles_partner_id)
#  index_bowlers_on_identifier          (identifier)
#  index_bowlers_on_person_id           (person_id)
#  index_bowlers_on_team_id             (team_id)
#  index_bowlers_on_tournament_id       (tournament_id)
#

FactoryBot.define do
  factory :bowler do
    position { 1 }

    association :person, strategy: :create
  end
end
