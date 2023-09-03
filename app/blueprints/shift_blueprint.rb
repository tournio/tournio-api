# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :display_order

  field :unpaid_count do |s, _|
    0
  end

  field :paid_count do |s, _|
    0
  end
end
