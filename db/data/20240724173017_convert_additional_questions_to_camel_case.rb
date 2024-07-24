# frozen_string_literal: true

class ConvertAdditionalQuestionsToCamelCase < ActiveRecord::Migration[7.1]
  def up
    ExtendedFormField.all.map { |eff| eff.update(name: eff.name.camelize(:lower))}
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
