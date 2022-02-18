# frozen_string_literal: true

class UserBlueprint < Blueprinter::Base
  identifier :identifier

  fields :email, :role

  association :tournaments, blueprint: TournamentBlueprint
end
