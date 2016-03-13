if Rails.env == 'production'
	Raven.configure do |config|
	  config.dsn = ENV['sentry_dsn']
	  config.environments = %w[production staging]
	end
end