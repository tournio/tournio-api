# frozen_string_literal: true

$redis = Redis.new(url: ENV['REDIS_URL'], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
Redis.exists_returns_integer = true
