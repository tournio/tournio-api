# frozen_string_literal: true

class FreeEntryBlueprint < Blueprinter::Base
  identifier :identifier
  fields :unique_code, :confirmed

  view :director_list do
    field :id
    association :bowler, blueprint: BowlerBlueprint
  end
end
