web: bundle exec puma -C config/puma.rb
resque: env TERM_CHILD=1 bundle exec rake resque:work QUEUE='*'
