# frozen_string_literal: true

class ListBowlerSerializer < BowlerSerializer
  attributes :position

  one :team, resource: TeamSerializer
  one :doubles_partner, resource: BowlerSerializer
end
