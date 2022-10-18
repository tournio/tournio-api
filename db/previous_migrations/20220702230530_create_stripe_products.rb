class CreateStripeProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_products do |t|
      t.references :purchasable_item, null: false
      t.string :product_id
      t.string :price_id

      t.timestamps

      t.index [:product_id, :price_id]
    end
  end
end
