# frozen_string_literal: true

class PurchasableItemBlueprint < Blueprinter::Base
  identifier :identifier
  fields :category, :determination, :refinement, :name, :value, :configuration
end
