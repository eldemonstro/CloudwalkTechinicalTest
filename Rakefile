require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'

desc "Start the server"
task :server do
  if ActiveRecord::Base.connection.migration_context.needs_migration?
    puts "Migrations are pending. Make sure to run `rake db:migrate` first."
    return
  end
  
  ENV["PORT"] ||= "3000"

  exec "ruby transaction_approver_api.rb"
end

desc 'Tests'
task :test do
  Dir.glob('./tests/**/*_test.rb').each { |t| exec "ruby #{t}" }
end
  
desc "Start the console"
task :console do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  Pry.start
end