class CreateSignups < ActiveRecord::Migration[7.1]
  def change
    create_table :signups do |t|
      t.string :aasm_state, default: "initial"
      t.references :bowler
      t.references :purchasable_item

      t.timestamps
    end
  end
end
