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

  after_create do
    shift.update(requested: shift.requested + 1)
  end

  before_destroy do
    if confirmed_at.present?
      shift.update(confirmed: shift.confirmed - 1)
    else
      shift.update(requested: shift.requested - 1)
    end
  end

  aasm timestamps: true do
    state :requested, initial: true
    state :confirmed

    event :confirm do
      transitions from: :requested, to: :confirmed

      after do
        shift.update(confirmed: shift.confirmed + 1, requested: shift.requested - 1)
      end
    end
  end
end
