class CreateBowlersShifts < ActiveRecord::Migration[7.0]
  def change
    create_table :bowlers_shifts do |t|
      t.references :bowler, null: false
      t.references :shift, null: false

      t.string :aasm_state, null: false
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
