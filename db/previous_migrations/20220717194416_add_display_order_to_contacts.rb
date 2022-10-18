class AddDisplayOrderToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :display_order, :integer
  end
end
