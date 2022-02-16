class HttpAuth
  class << self
    def jwt_from_auth_header(header)
      token_part = header.split(' ').last
      JsonWebToken.decode(token_part)
    end
  end
end
