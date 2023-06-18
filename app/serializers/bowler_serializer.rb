# frozen_string_literal: true

class BowlerSerializer
  include Alba::Resource

  transform_keys :lower_camel

  root_key :bowler

  attributes :identifier
  attribute :registered_on do |b|
    b.created_at.strftime('%F')
  end
  attribute :list_name do |b|
    TournamentRegistration.person_list_name(b.person)
  end
  attribute :full_name do |b|
    TournamentRegistration.person_display_name(b.person)
  end
  attribute :usbc_id do |b|
    b.usbc_id
  end
  attribute :team_name do |b|
    TournamentRegistration.team_display_name(b.team) if b.team.present?
  end

  one :doubles_partner, resource: BowlerSerializer

  # Alba doesn't support associations of the has_one :through variety. At least, not yet.
  # one :shift, resource: ShiftSerializer
  attribute :shift do |b|
    ShiftSerializer.new(b.shift).to_h
  end
end
