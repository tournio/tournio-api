class CreateDataPoints < ActiveRecord::Migration[7.0]
  def change
    create_table :data_points do |t|
      t.string :key, index: true, null: false
      t.string :value, null: false
      t.references :tournament, index: true

      t.timestamps
    end

    add_index :data_points, :created_at
    add_index :bowlers, :created_at
  end
end

# On a bowler registering with a team:
#   DataPoint.create(
#     key: 'registration_type'
#     value: one of the elements of Shift.SUPPORTED_REGISTRATION_TYPES,
#     tournament: bowler.tournament
#   )
