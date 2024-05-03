# frozen_string_literal: true

class ContactSerializer < JsonSerializer
  attributes :identifier, :name, :role, :email
end
