# frozen_string_literal: true

# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  description   :string
#  display_order :integer          default(1), not null
#  event_string  :string
#  group_title   :string
#  identifier    :string           not null
#  is_full       :boolean          default(FALSE)
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_identifier     (identifier) UNIQUE
#  index_shifts_on_tournament_id  (tournament_id)
#
class ShiftSerializer < JsonSerializer
  attributes :identifier,
    :name,
    :description,
    :capacity,
    :display_order,
    :is_full,
    :group_title,
    :event_string

  # If there's a team event, returns just team count; otherwise, return bowler count
  attribute :tally do |shift|
    result = shift.bowlers.count
    if shift.events.team.any?
      result = shift.teams.count
    end

    result

    # @doubles Do we want to handle doubles-only events differently?
  end
end
