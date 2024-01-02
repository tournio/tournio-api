# frozen_string_literal: true

class RemoveOldConfigItems < ActiveRecord::Migration[7.1]
  def up
    ConfigItem.where(key: %w(automatic_discount_voids automatic_late_fees)).destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
