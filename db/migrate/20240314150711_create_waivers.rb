class CreateWaivers < ActiveRecord::Migration[7.1]
  def change
    create_table :waivers do |t|
      t.string :identifier
      t.string :name
      t.integer :amount
      t.string :created_by

      t.references :bowler
      t.references :purchasable_item

      t.timestamps
    end
  end
end
