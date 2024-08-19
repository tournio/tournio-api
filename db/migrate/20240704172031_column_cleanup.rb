class ColumnCleanup < ActiveRecord::Migration[7.1]
  def change
    remove_column :teams, :initial_size, { type: :integer }
    remove_column :teams, :options, { type: :jsonb }
    change_column_default :tournaments, :details, from: {"enabled_registration_options"=>["new_team", "solo", "join_team"]}, to: {"enabled_registration_options"=>[]}
  end
end
