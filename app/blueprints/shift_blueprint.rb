# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :display_order, :details

  field :requested_count do |s, _|
    s.requested
  end

  field :confirmed_count do |s, _|
    s.confirmed
  end
end
