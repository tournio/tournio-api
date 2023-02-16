class MakePurchasesVoidable < ActiveRecord::Migration[7.0]
  def change
    add_column :purchases, :voided_at, :datetime, if_not_exists: true
    add_column :purchases, :void_reason, :string, if_not_exists: true
  end
end
