# frozen_string_literal: true

class TournamentOrgSerializer < BasicTournamentOrgSerializer

  one :stripe_account
  many :tournaments
  many :users
end
