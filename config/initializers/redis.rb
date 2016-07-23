if ENV["REDISTOGO_URL"]
  uri = URI.parse(ENV["REDISTOGO_URL"])
  REDIS ||= Redis.new(
    host: uri.host,
    port: uri.port,
    password: uri.password,
    thread_safe: true
  )
end
