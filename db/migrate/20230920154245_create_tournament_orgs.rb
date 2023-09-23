class CreateTournamentOrgs < ActiveRecord::Migration[7.0]
  def change
    create_table :tournament_orgs do |t|
      t.string :name, null: false
      t.string :identifier, null: false

      t.timestamps

      t.index ["identifier"], name: "index_tournament_orgs_on_identifier", unique: true
    end
  end
end
