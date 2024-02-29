# frozen_string_literal: true

class UserSerializer < JsonSerializer
  attributes :identifier,
    :email,
    :first_name,
    :last_name,
    :role,
    last_sign_in_at: [String, ->(object) { object.present? ? object.strftime('%F %r') : nil }]

  many :tournament_orgs, resource: BasicTournamentOrgSerializer
  # many :tournaments, resource: TournamentSerializer
end
