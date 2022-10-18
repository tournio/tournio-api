class DropDisplayOrderFromContacts < ActiveRecord::Migration[7.0]
  def change
    remove_column :contacts, :display_order, :integer
  end
end
