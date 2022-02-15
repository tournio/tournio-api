class ContactBlueprint < Blueprinter::Base
  identifier :id

  field :name
  field :email
  field :role do |c|
    c.role&.titlecase || c.notes
  end
end
