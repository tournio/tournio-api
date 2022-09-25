class CreateEventScratchDivisions < ActiveRecord::Migration[7.0]
  def change
    create_join_table :events, :scratch_divisions
    add_index :events_scratch_divisions, [:event_id, :scratch_division_id], unique: true, name: 'event_division_idx'
  end
end
