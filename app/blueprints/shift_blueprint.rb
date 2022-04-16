# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :description, :capacity

  field :requested_count do |s, _|
    s.requested
  end

  field :confirmed_count do |s, _|
    s.confirmed
  end
end
