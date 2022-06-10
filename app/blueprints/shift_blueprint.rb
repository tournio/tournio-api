# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :display_order

  field :requested_count do |s, _|
    s.requested
  end

  field :confirmed_count do |s, _|
    s.confirmed
  end

  field :events do |s, _|
    s.details['events']
  end

  field :registration_types do |s, _|
    types = {}
    Shift::SUPPORTED_REGISTRATION_TYPES.each do |t|
      types[t] = s.details['registration_types'].include?(t)
    end
    types
  end
end
