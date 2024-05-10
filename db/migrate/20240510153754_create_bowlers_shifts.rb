class CreateBowlersShifts < ActiveRecord::Migration[7.1]
  def change
    create_join_table :bowlers, :shifts do |t|
      t.index :bowler_id
      t.index :shift_id
    end
  end
end
