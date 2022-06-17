class ChangeDefaultShiftDetails < ActiveRecord::Migration[7.0]
  def change
    change_column_default :shifts, :details, { events: [], registration_types: %w(new_team solo join_team) }
  end
end
