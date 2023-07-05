# frozen_string_literal: true

# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  confirmed     :integer          default(0), not null
#  description   :string
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  name          :string
#  requested     :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_identifier     (identifier) UNIQUE
#  index_shifts_on_tournament_id  (tournament_id)
#
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
