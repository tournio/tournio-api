# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id            :bigint           not null, primary key
#  identifier    :string           not null
#  name          :string
#  options       :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint
#
# Indexes
#
#  index_teams_on_identifier     (identifier) UNIQUE
#  index_teams_on_tournament_id  (tournament_id)
#

FactoryBot.define do
  factory :team do
    name { 'Strike Force' }
    tournament
  end

  trait :standard_one_bowler do
    after(:create) do |team, _|
      create :bowler, position: 1, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
    end
  end

  trait :standard_two_bowlers do
    after(:create) do |team, _|
      create :bowler, position: 1, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
      create :bowler, position: 2, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
    end
  end

  trait :standard_three_bowlers do
    after(:create) do |team, _|
      create :bowler, position: 1, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
      create :bowler, position: 2, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
      create :bowler, position: 3, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
    end
  end

  trait :standard_full_team do
    after(:create) do |team, _|
      create :bowler, position: 1, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
      create :bowler, position: 2, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
      create :bowler, position: 3, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
      create :bowler, position: 4, team: team, tournament: team.tournament, shift: team.tournament.shifts.first
    end
  end
end
