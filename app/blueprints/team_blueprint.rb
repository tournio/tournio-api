# frozen_string_literal: true

class TeamBlueprint < Blueprinter::Base
  identifier :identifier

  association :tournament, blueprint: TournamentBlueprint

  view :list do
    field :name do |t, _|
      t.name.length.positive? ? t.name : TournamentRegistration.team_display_name(t)
    end
    field :created_at, name: :date_registered, datetime_format: '%F'
    field :size do |t, _|
      t.bowlers.count
    end
  end

  view :detail do
    include_view :list

    association :bowlers, blueprint: BowlerBlueprint do |team, _|
      team.bowlers.order(position: :asc)
    end
  end

  view :director_list do
    field :name do |t, _|
      t.name.length.positive? ? t.name : TournamentRegistration.team_display_name(t) || 'uhh...'
    end
    field :created_at, name: :date_registered, datetime_format: '%F'
    field :size do |t, _|
      t.bowlers.count
    end
  end

  view :director_detail do
    include_view :director_list

    association :bowlers, blueprint: BowlerBlueprint, view: :director_team_detail do |team, _|
      team.bowlers.order(position: :asc)
    end
  end
end
