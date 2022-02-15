# frozen_string_literal: true

class PersonBlueprint < Blueprinter::Base
  fields :first_name, :last_name

  view :detail do
    fields :igbo_id, :usbc_id
  end
end
