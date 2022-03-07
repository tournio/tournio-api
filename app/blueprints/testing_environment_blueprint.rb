# frozen_string_literal: true

class TestingEnvironmentBlueprint < Blueprinter::Base
  field :settings do |te, options|
    output = {}
    te.conditions.each_pair do |condition, setting|
      output[condition] = {
        name: condition,
        display_name: condition.to_s.humanize,
        display_value: setting.to_s.humanize,
        value: setting,
      }
    end
    output
  end
end
