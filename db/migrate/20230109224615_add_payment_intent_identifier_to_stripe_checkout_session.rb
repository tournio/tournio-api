class AddPaymentIntentIdentifierToStripeCheckoutSession < ActiveRecord::Migration[7.0]
  def change
    add_column :stripe_checkout_sessions, :payment_intent_identifier, :string
    add_index :stripe_checkout_sessions, :payment_intent_identifier
  end
end
