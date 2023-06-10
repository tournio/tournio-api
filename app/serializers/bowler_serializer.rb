# frozen_string_literal: true

class BowlerSerializer
  include Alba::Resource

  transform_keys :lower_camel

  root_key :bowler

  attributes :identifier
  attribute :registered_on do |b|
    b.created_at.strftime('%F')
  end
  attribute :name do |b|
    TournamentRegistration.person_display_name(b.person)
  end
  attribute :doubles_partner do |b|
    TournamentRegistration.person_display_name(b.doubles_partner.person) if b.doubles_partner.present?
  end
  attribute :usbc_id do |b|
    b.usbc_id
  end
  attribute :team_name do |b|
    TournamentRegistration.team_display_name(b.team) if b.team.present?
  end

end
