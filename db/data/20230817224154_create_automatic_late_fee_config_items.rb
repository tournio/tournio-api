# frozen_string_literal: true

class CreateAutomaticLateFeeConfigItems < ActiveRecord::Migration[7.0]
  def up
    Tournament.all.each do |t|
      t.config_items << ConfigItem.new(key: 'automatic_late_fees', label: 'Automatically Charge Unpaid Bowlers the Late Fee', value: false) unless t.config_items.exists?(key: 'automatic_late_fees')
    end
  end

  def down
    ConfigItem.where(key: 'automatic_late_fees').destroy_all
  end
end
