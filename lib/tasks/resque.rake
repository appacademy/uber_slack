require 'resque/tasks'

task 'resque:setup' => :environment do
  puts "Loading Rails environment for Resque"
  task :setup => :environment do
    ActiveRecord::Base.descendants.each { |klass|  klass.columns }
  end
end
