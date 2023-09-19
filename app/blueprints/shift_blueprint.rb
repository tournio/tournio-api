# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :display_order, :is_full

  field :team_count do |shift, _|
    shift.teams.count
  end
end
