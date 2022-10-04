class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.references :tournament, null: false
      t.integer :roster_type, null: false
      t.string :name, null: false
      t.boolean :required, default: true
      t.boolean :scratch, default: false
      t.boolean :permit_multiple_entries, default: false
      t.integer :game_count

      t.timestamps
    end
  end
end
