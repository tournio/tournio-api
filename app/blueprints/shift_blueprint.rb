# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :display_order, :is_full, :group_title, :event_string

  field :team_count do |shift, _|
    shift.teams.count
  end

  field :bowler_count do |shift, _|
    shift.bowlers.count
  end

  field :tally do |shift, _|
    result = shift.bowlers.count
    if shift.events.team.any?
      result = shift.teams.count
    end

    result

    # @doubles Do we want to handle doubles-only events differently?
  end
end
