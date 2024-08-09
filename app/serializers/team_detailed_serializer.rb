# frozen_string_literal: true

class TeamDetailedSerializer < TeamSerializer
  one :tournament, resource: TournamentSerializer
  has_many :bowlers, resource: TeamBowlerSerializer
  has_many :shifts, resource: ShiftSerializer
end
