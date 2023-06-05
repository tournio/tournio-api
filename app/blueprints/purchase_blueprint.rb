# frozen_string_literal: true

class PurchaseBlueprint < Blueprinter::Base
  identifier :identifier
  fields :name, :value, :amount, :configuration, :determination, :category
  field :paid_at, datetime_format: '%b %-d, %Y'
  field :purchasable_item_identifier do |p, _|
    p.purchasable_item.identifier
  end
  field :voided_at, datetime_format: '%b %-d, %Y'
end
