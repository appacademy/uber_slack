require_relative 'redis'

uri = URI.parse(ENV["REDISTOGO_URL"])
Resque.redis = REDIS
