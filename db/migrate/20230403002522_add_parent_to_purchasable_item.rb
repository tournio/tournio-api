class AddParentToPurchasableItem < ActiveRecord::Migration[7.0]
  def change
    add_column :purchasable_items, :parent_id, :bigint
  end
end
