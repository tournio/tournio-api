class CreateShifts < ActiveRecord::Migration[7.0]
  def change
    create_table :shifts do |t|
      t.string :name, null: false
      t.string :description, null: false
      t.integer :display_order, null: false, default: 1
      t.integer :capacity, null: false, default: 40
      t.integer :desired, null: false, default: 0
      t.integer :confirmed, null: false, default: 0
      t.references :tournament, null: false

      t.timestamps
    end
  end
end
