# frozen_string_literal: true

class CamelCaseBowlerFormFields < ActiveRecord::Migration[7.1]
  def up
    items = ConfigItem.where(key: 'bowler_form_fields')
    items.each do |item|
      fields = item.value.split(' ')
      converted = fields.map { |f| f.camelize(:lower) }
      item.update(value: converted.join(' '))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
