ENV["REDISTOGO_URL"] = 'redis://redistogo:a5bdb4862b765ca27da42aff153df735@tarpon.redistogo.com:11246'
uri = URI.parse(ENV["REDISTOGO_URL"])
Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)
