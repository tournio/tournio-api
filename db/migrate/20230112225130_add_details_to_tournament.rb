class AddDetailsToTournament < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :details, :jsonb, default: { enabled_registration_options: %w(new_team solo join_team) }
  end
end
