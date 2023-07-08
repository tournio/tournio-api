class AddEnabledToPurchasableItems < ActiveRecord::Migration[7.0]
  def change
    add_column :purchasable_items, :enabled, :boolean, default: true
  end
end
