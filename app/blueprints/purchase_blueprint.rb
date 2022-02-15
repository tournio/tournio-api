# frozen_string_literal: true

class PurchaseBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :value, :amount, :configuration, :determination, :category
  field :paid_at, datetime_format: '%b %-d, %Y'
end
