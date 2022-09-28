class CreateStripeCheckoutSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_checkout_sessions do |t|
      t.references :bowler, null: false
      t.string :identifier, null: false, index: true
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
