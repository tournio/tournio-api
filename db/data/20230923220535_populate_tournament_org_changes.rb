# frozen_string_literal: true

class PopulateTournamentOrgChanges < ActiveRecord::Migration[7.0]
  def up
    # for each tournament:
    #  - create an org
    #  - associate it with its org
    #  - link its stripe account with the org
    #  - for each of its users:
    #    - link the user to the org
    Tournament.each do |tournament|
      org = TournamentOrg.create(
        name: tournament.name,
        stripe_account_id: tournament.stripe_account_id
      )
      tournament.update(tournament_org: org)
      User.where(tournament_id: tournament.id).each do |user|
        org.users << user
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
