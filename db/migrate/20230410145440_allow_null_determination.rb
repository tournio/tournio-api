class AllowNullDetermination < ActiveRecord::Migration[7.0]
  def change
    change_column :purchasable_items, :determination, :string, null: true
  end
end
