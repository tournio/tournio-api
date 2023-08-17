# frozen_string_literal: true

class CreateAutomaticLateFeeConfigItems < ActiveRecord::Migration[7.0]
  def up
    Tournament.all.each do |t|
      t.config_items << ConfigItem.new(key: 'automatic_late_fee', label: 'Add Late Fee to Unpaid Bowlers', value: false)
    end
  end

  def down
    ConfigItem.where(key: 'automatic_late_fee').destroy_all
  end
end
