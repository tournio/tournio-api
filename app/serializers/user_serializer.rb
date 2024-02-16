# frozen_string_literal: true

class UserSerializer < JsonSerializer
  attributes :identifier,
    :email,
    :first_name,
    :last_name,
    :last_sign_in_at,
    :role
end
