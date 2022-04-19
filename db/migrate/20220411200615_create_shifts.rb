class CreateShifts < ActiveRecord::Migration[7.0]
  def change
    create_table :shifts do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :description, null: false
      t.integer :display_order, null: false, default: 1
      t.integer :capacity, null: false, default: 40
      t.integer :requested, null: false, default: 0
      t.integer :confirmed, null: false, default: 0
      t.references :tournament, null: false

      t.timestamps

      t.index :identifier, unique: true
    end

    # create_index :shifts, :identifier, unique: true
  end
end
