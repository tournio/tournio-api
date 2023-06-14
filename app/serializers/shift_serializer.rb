# frozen_string_literal: true

class ShiftSerializer
  include Alba::Resource

  transform_keys :lower_camel

  root_key :shift

  attributes :identifier, :name, :description, :capacity, :display_order

  attribute :unpaid_count do |s|
    s.requested
  end

  attribute :paid_count do |s|
    s.confirmed
  end
end
