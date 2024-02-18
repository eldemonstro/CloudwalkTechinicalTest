require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
require './transaction_approver_api'
require "minitest/test_task"

ENV['APP_ENV'] = 'development'
ENV['RAILS_ENV'] ||= ENV['APP_ENV']

Minitest::TestTask.create(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_globs = ["test/**/*_test.rb"]
end

desc "Start the server"
task :server do
  if ActiveRecord::Base.connection.migration_context.needs_migration?
    puts "Migrations are pending. Make sure to run `rake db:migrate` first."
    return
  end
  
  ENV["PORT"] ||= "3000"

  exec "ruby transaction_approver_api.rb"
end
  
desc "Start the console"
task :console do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  Pry.start
end