# frozen_string_literal: true

module TeamBusiness
  def position_occupied?(pos)
    bowlers.pluck(:position).include?(pos)
  end

  def first_available_position
    occupied_positions = bowlers.pluck(:position)
    all_positions = (1..tournament.team_size).to_a
    available_positions = all_positions.difference(occupied_positions)
    available_positions.first
  end
end
