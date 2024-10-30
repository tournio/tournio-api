# frozen_string_literal: true

class DirectorContactSerializer < ContactSerializer
  attributes :notify_on_registration, :notify_on_payment, :notification_preference
end
