# frozen_string_literal: true
#
# == Schema Information
#
# Table name: teams
#
#  id            :bigint           not null, primary key
#  identifier    :string           not null
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  shift_id      :bigint
#  tournament_id :bigint
#
# Indexes
#
#  index_teams_on_identifier     (identifier) UNIQUE
#  index_teams_on_shift_id       (shift_id)
#  index_teams_on_tournament_id  (tournament_id)
#

class TeamSerializer < JsonSerializer
  attributes :identifier,
    :name,
    :created_at

  has_many :shifts
end
