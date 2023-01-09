class CreateStripePaymentIntents < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_payment_intents do |t|
      t.references :stripe_checkout_session, null: false
      t.string :identifier, null: false, index: true
      t.integer :amount_received, default: 0

      t.timestamps
    end
  end
end
