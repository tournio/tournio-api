# frozen_string_literal: true

class UserBlueprint < Blueprinter::Base
  identifier :identifier

  fields :email, :role, :last_sign_in_at
end
