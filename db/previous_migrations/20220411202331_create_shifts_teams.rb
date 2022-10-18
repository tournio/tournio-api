class CreateShiftsTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :shifts_teams do |t|
      t.references :shift, null: false, index: true
      t.references :team, null: false, index: true

      t.string :aasm_state, null: false
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
