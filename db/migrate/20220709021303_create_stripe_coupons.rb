class CreateStripeCoupons < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_coupons do |t|
      t.references :purchasable_item, null: false
      t.string :coupon_id, index: true

      t.timestamps
    end
  end
end
