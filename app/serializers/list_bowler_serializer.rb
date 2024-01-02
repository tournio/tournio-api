# frozen_string_literal: true

class ListBowlerSerializer < BowlerSerializer
  attributes :position

  #
  # @early-discount Remove this when the frontend list no longer uses ReactTable to display a list
  # ...
  attribute :team_name do |b|
    b.team&.name
  end

  one :team, resource: TeamSerializer
  one :doubles_partner, resource: BowlerSerializer
end
