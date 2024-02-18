require 'sinatra'

before do
  auth_token = request.env['AUTHENTICATION_TOKEN']

  halt 403 if auth_token != 'GOOD_TOKEN'
end

get '/' do
  'Hello World'
end