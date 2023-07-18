# frozen_string_literal: true

# == Schema Information
#
# Table name: bowlers
#
#  id                 :bigint           not null, primary key
#  identifier         :string
#  position           :integer
#  verified_data      :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  doubles_partner_id :bigint
#  person_id          :bigint
#  team_id            :bigint
#  tournament_id      :bigint
#
# Indexes
#
#  index_bowlers_on_created_at          (created_at)
#  index_bowlers_on_doubles_partner_id  (doubles_partner_id)
#  index_bowlers_on_identifier          (identifier)
#  index_bowlers_on_person_id           (person_id)
#  index_bowlers_on_team_id             (team_id)
#  index_bowlers_on_tournament_id       (tournament_id)
#
class BowlerSerializer
  include Alba::Resource

  transform_keys :lower_camel

  root_key :bowler

  attributes :identifier,
    :position,
    :shift

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
  # one :shift do |b|
  #   b.shift
  # end, resource: ShiftSerializer
end
