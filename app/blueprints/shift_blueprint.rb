# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :display_order

  field :unpaid_count do |s, _|
    s.requested
  end

  field :paid_count do |s, _|
    s.confirmed
  end
end
