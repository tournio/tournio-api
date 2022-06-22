class CreateStripeAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_accounts do |t|
      t.references :tournament, null: false
      t.datetime :onboarding_completed_at

      t.timestamps
    end
  end
end
