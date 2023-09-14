# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :requested, :display_order

  # @deprecated
  field :unpaid_count do |s, _|
    0
  end

  # @deprecated
  field :paid_count do |s, _|
    0
  end
end
