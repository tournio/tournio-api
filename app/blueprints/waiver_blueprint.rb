# frozen_string_literal: true

class WaiverBlueprint < Blueprinter::Base
  identifier :identifier
  fields :created_by, :created_at, :amount, :name
end
