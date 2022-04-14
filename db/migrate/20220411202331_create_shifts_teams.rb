class CreateShiftsTeams < ActiveRecord::Migration[7.0]
  def change
    create_join_table :shifts, :teams do |t|
      t.string :aasm_state, null: false
      t.datetime :confirmed_at

      t.timestamps

      t.index :shift_id
      t.index :team_id
    end
  end
end
