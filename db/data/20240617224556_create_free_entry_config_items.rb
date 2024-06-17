# frozen_string_literal: true

class CreateFreeEntryConfigItems < ActiveRecord::Migration[7.1]
  def up
    Tournament.all.each do |tournament|
      tournament.config_items << ConfigItem.new(key: 'enable_free_entries', value: 'true', label: 'Accept free entry codes from bowlers')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
