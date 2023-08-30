class AddInitialSizeToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :initial_size, :integer, default: 4
  end
end
