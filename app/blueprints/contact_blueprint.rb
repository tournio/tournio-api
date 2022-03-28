class ContactBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :notify_on_registration, :notify_on_payment, :notification_preference
  field :role do |c|
    c.role&.titlecase || c.notes
  end
end
