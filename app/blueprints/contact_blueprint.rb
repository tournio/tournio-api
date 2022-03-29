class ContactBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :role, :notify_on_registration, :notify_on_payment, :notification_preference
end
