class CreateStripeEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_events do |t|
      t.string :event_identifier, index: true

      t.timestamps
    end
  end
end
