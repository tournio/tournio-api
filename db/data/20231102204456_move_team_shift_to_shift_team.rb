# frozen_string_literal: true

class MoveTeamShiftToShiftTeam < ActiveRecord::Migration[7.0]
  def up
    Tournament.all.each do |tournament|
      tournament.teams.where.not(shift_id: nil).each do |team|
        shift = Shift.find(team.shift_id)
        team.shifts << shift
      end
    end
  end

  def down
    Tournament.all.each do |tournament|
      tournament.teams.includes(:shifts).each do |team|
        shift = team.shifts.first
        next unless shift.present?
        team.update(shift_id: shift.id)
      end
    end
  end
end
