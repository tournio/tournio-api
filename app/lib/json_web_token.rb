class JsonWebToken
  class << self
    def decode(token)
      token_body = JWT.decode(token, Rails.application.credentials.fetch(:secret_key_base))[0]
      HashWithIndifferentAccess.new token_body
    end
  end
end
