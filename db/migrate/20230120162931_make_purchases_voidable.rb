class MakePurchasesVoidable < ActiveRecord::Migration[7.0]
  def change
    add_column :purchases, :voided_at, :datetime
    add_column :purchases, :void_reason, :string
  end
end
