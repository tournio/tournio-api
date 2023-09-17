# frozen_string_literal: true

class TeamDetailedSerializer < TeamSerializer
  has_many :bowlers, resource: BowlerSerializer
end
