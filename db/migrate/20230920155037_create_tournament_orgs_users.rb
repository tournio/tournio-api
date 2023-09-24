class CreateTournamentOrgsUsers < ActiveRecord::Migration[7.0]
  def change
    create_join_table :tournament_orgs, :users do |t|
      t.index :tournament_org_id
      t.index :user_id

      t.timestamps
    end
  end
end
