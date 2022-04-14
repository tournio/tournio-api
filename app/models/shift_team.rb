# t.bigint "shift_id", null: false
# t.bigint "team_id", null: false
# t.string "aasm_state", null: false
# t.datetime "confirmed_at"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false
# t.index ["shift_id"], name: "index_shifts_teams_on_shift_id"
# t.index ["team_id"], name: "index_shifts_teams_on_team_id"

class ShiftTeam < ApplicationRecord
  include AASM

  self.table_name = 'shifts_tables'

  belongs_to :shift
  belongs_to :team

  after_create do
    shift.update(desired: shift.desired + 1)
  end

  aasm do
    state :desired, initial: true
    state :confirmed

    event :confirm do
      transitions from: :desired, to: :confirmed

      after do
        shift.update(confirmed: shift.confirmed + 1)
      end
    end
  end
end
