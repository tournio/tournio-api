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

  field :permit_new_teams do |s, _|
    s.details['permit_new_teams']
  end

  field :permit_solo do |s, _|
    s.details['permit_solo']
  end

  field :permit_joins do |s, _|
    s.details['permit_joins']
  end

  field :permit_partnering do |s, _|
    s.details['permit_partnering']
  end
end
