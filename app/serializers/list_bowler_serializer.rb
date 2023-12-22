# frozen_string_literal: true

class ListBowlerSerializer < BowlerSerializer
  attributes :position,
    :address1,
    :address2,
    :birth_day,
    :birth_month,
    :city,
    :country,
    :postal_code,
    :state

  attribute :registered_on do |b|
    b.created_at.strftime('%F')
  end
  attribute :list_name do |b|
    TournamentRegistration.person_list_name(b.person)
  end
  attribute :team_name do |b|
    TournamentRegistration.team_display_name(b.team) if b.team.present?
  end

  one :doubles_partner, resource: BowlerSerializer
end
