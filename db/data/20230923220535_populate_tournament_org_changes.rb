# frozen_string_literal: true

class PopulateTournamentOrgChanges < ActiveRecord::Migration[7.0]
  def up
    # for each tournament:
    #  - create an org
    #  - associate it with its org
    #  - link its stripe account with the org
    #  - for each of its users:
    #    - link the user to the org
    Tournament.all.each do |tournament|
      org = TournamentOrg.create(name: tournament.name)
      tournament.stripe_account.update(tournament_org_id: org.id)
      tournament.update(tournament_org: org)
      tournament.users.each do |user|
        org.users << user
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
