require 'sinatra'
require 'sinatra/activerecord'
require './models/transaction'

set :database_file, "./config/database.yml"

before do
  auth_token = request.env['AUTHENTICATION_TOKEN']

  # JWT.authorization.call(auth_token)

  halt 403 if auth_token != 'GOOD_TOKEN'
end

post '/' do
  require 'pry'; binding.pry

  transaction = Transaction.new
end