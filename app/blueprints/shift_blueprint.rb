# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  fields :name, :description, :capacity

  field :desired_count do |s, _|
    s.desired
  end

  field :confirmed_count do |s, _|
    s.confirmed
  end
end
