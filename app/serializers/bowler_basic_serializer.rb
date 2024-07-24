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
class BowlerBasicSerializer < JsonSerializer

  attributes :identifier,
    :email,
    :first_name,
    :last_name,
    :phone,
    :preferred_name,
    :usbc_id

  attribute :registered_on do |b|
    b.created_at.strftime('%F')
  end
  attribute :list_name do |b|
    TournamentRegistration.person_list_name(b.person)
  end
  attribute :full_name do |b|
    TournamentRegistration.person_display_name(b.person)
  end
end
