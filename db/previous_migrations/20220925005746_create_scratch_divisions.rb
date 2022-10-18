class CreateScratchDivisions < ActiveRecord::Migration[7.0]
  def change
    create_table :scratch_divisions do |t|
      t.references :tournament, null: false
      t.string :key, null: false
      t.string :name
      t.integer :low_average, null: false, default: 0
      t.integer :high_average, null: false, default: 300

      t.timestamps
    end
  end
end
