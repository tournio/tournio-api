# frozen_string_literal: true

class TournamentOrgSerializer < JsonSerializer
  attributes :identifier,
    :name

  one :stripe_account
  many :users
end
