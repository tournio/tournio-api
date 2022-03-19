class ExtendedFormFieldBlueprint < Blueprinter::Base
  identifier :id

  fields :label, :name, :validation_rules
end
