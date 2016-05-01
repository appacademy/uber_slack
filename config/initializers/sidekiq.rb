Sidekiq.options[:concurrency] = Integer(ENV['SIDEKIQ_CONCURRENCY'] || 6)
pool_size = Sidekiq.options[:concurrency] + 2

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDISTOGO_URL'] }

end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDISTOGO_URL'] }
end
