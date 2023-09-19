# frozen_string_literal: true

class CreateStripeReceiptsConfigItems < ActiveRecord::Migration[7.0]
  def up
    Tournament.upcoming.each do |t|
      t.config_items << ConfigItem.new(key: 'stripe_receipts', value: false, label: 'Send receipts via Stripe') unless ConfigItem.exists?(key: 'stripe_receipts', tournament: t)
    end
  end

  def down
  end
end
