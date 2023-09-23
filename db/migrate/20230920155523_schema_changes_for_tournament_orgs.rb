class SchemaChangesForTournamentOrgs < ActiveRecord::Migration[7.0]
  def change
    add_reference :tournaments, :tournament_org
    add_reference :stripe_accounts, :tournament_org
  end
end
