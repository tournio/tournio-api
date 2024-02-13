# frozen_string_literal: true

class CreateSignupsConfigItem < ActiveRecord::Migration[7.1]
  KEY = 'enable_unpaid_signups'

  def up
    Tournament.upcoming.each do |t|
      ConfigItem.create(
        tournament: t,
        key: KEY,
        value: 'true',
        label: 'Allow unpaid signups for optional events'
      ) unless ConfigItem.exists?(tournament_id: t.id, key: KEY)
    end
  end

  def down
  end
end
