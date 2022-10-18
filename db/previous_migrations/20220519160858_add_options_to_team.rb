class AddOptionsToTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :options, :jsonb, default: {}
  end
end
