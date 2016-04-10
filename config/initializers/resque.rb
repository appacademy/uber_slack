if redis_url = ENV["REDISTOGO_URL"]
  uri = URI.parse(redis_url)
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)
end
