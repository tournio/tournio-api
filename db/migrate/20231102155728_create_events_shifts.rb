class CreateEventsShifts < ActiveRecord::Migration[7.0]
  def change
    create_join_table :events, :shifts do |t|
      t.index :event_id
      t.index :shift_id
    end
  end
end
