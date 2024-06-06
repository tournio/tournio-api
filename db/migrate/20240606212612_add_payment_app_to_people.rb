class AddPaymentAppToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :payment_app, :string
  end
end
