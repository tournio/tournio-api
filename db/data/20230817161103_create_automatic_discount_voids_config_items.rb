# frozen_string_literal: true

class CreateAutomaticDiscountVoidsConfigItems < ActiveRecord::Migration[7.0]
  def up
    Tournament.all.each do |t|
      t.config_items << ConfigItem.new(key: 'automatic_discount_voids', label: 'Automatically Void Early Discounts', value: false)
    end
  end

  def down
    ConfigItem.where(key: 'automatic_discount_voids').destroy_all
  end
end
