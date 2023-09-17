# frozen_string_literal: true

class ShiftBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :description, :capacity, :requested, :display_order, :is_full
end
