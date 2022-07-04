class CreateExternalPayments < ActiveRecord::Migration[7.0]
  def change
    create_table :external_payments do |t|
      t.integer :payment_type, null: false
      t.string :paypal_identifier
      t.string :stripe_payment_intent_id
      t.jsonb :details

      t.timestamps
    end

    remove_column :purchases, :paypal_order_id, type: :integer
    add_reference :purchases, :external_payment
  end
end
