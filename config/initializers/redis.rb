# frozen_string_literal: true

Redis.exists_returns_integer = true
$redis = Redis.new(url: ENV['REDIS_URL'])
Redis.exists_returns_integer = true
