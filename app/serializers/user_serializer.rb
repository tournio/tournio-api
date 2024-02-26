# frozen_string_literal: true

class UserSerializer < JsonSerializer
  attributes :identifier,
    :email,
    :first_name,
    :last_name,
    :last_sign_in_at,
    :role

  many :tournament_orgs, resource: BasicTournamentOrgSerializer
  many :tournaments, resource: TournamentSerializer
end
