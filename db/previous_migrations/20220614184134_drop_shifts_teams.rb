class DropShiftsTeams < ActiveRecord::Migration[7.0]
  def change
    drop_table :shifts_teams;
  end
end
