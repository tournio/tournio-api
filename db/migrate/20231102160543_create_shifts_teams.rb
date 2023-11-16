class CreateShiftsTeams < ActiveRecord::Migration[7.0]
  def change
    create_join_table :shifts, :teams do |t|
      t.index :team_id
      t.index :shift_id
    end
  end
end
