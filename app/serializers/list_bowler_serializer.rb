# frozen_string_literal: true

class ListBowlerSerializer < BowlerSerializer
  #
  # @early-discount Remove this when the frontend list no longer uses ReactTable to display a list
  # ...
  attribute :teamName do |b|
    b.team&.name
  end

  one :team, resource: TeamSerializer
  one :doubles_partner, resource: BowlerSerializer
end
