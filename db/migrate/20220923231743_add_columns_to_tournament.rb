class AddColumnsToTournament < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :abbreviation, :string
    add_column :tournaments, :location, :string
    add_column :tournaments, :end_date, :date
    add_column :tournaments, :timezone, :string, default: 'America/New_York'
    add_column :tournaments, :entry_deadline, :datetime
  end
end
