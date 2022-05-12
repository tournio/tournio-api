# == Schema Information
#
# Table name: shifts_teams
#
#  id           :bigint           not null, primary key
#  aasm_state   :string           not null
#  confirmed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  shift_id     :bigint           not null
#  team_id      :bigint           not null
#
# Indexes
#
#  index_shifts_teams_on_shift_id  (shift_id)
#  index_shifts_teams_on_team_id   (team_id)
#

class ShiftTeam < ApplicationRecord
  include AASM

  self.table_name = 'shifts_teams'

  belongs_to :shift
  belongs_to :team

  aasm timestamps: true do
    state :requested, initial: true
    state :confirmed

    event :confirm do
      transitions from: :requested, to: :confirmed

      after do
        change = team.bowlers.count
        shift.update(confirmed: shift.confirmed + change, requested: shift.requested - change)
      end
    end
  end
end
