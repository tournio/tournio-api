# frozen_string_literal: true

class UserBlueprint < Blueprinter::Base
  identifier :identifier

  fields :email, :role
  field :last_sign_in_at, datetime_format: '%F %R', default: 'n/a'

  association :tournaments, blueprint: TournamentBlueprint
end
