# == Schema Information
#
# Table name: bowlers_shifts
#
#  id           :bigint           not null, primary key
#  aasm_state   :string           not null
#  confirmed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  bowler_id    :bigint           not null
#  shift_id     :bigint           not null
#
# Indexes
#
#  index_bowlers_shifts_on_bowler_id  (bowler_id)
#  index_bowlers_shifts_on_shift_id   (shift_id)
#
class BowlerShift < ApplicationRecord
  include AASM

  self.table_name = 'bowlers_shifts'

  belongs_to :bowler
  belongs_to :shift

  after_create do
    shift.update(requested: shift.requested + 1) if requested?
    shift.update(confirmed: shift.confirmed + 1) if confirmed?
  end

  before_destroy do
    shift.update(requested: shift.requested - 1) if requested?
    shift.update(confirmed: shift.confirmed - 1) if confirmed?
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
