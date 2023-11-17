# frozen_string_literal: true

class CreateBowlerFormFieldRows < ActiveRecord::Migration[7.0]
  def up
    Tournament.upcoming.each do |t|
      t.config_items << ConfigItem.new(key: 'bowler_form_fields', label: 'Bowler Form Fields', value: 'address1 city state country postal_code usbc_id date_of_birth') unless t.config_items.exists?(key: 'bowler_form_fields')
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
