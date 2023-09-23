# frozen_string_literal: true

class PopulateTournamentOrgChanges < ActiveRecord::Migration[7.0]
  def up
    # for each tournament:
    #  - create an org
    #  - associate it with its org
    #  - link its stripe account with the org
    #  - for each of its users:
    #    - link the user to the org
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
