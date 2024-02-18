require 'sinatra'
require 'sinatra/activerecord'
require "sinatra/json"
require "json"
require './models/transaction'
require './models/configuration'

set :database_file, "./config/database.yml"
set :bind, '0.0.0.0'

before do
  auth_token = request.env['HTTP_AUTHENTICATION_TOKEN'] || request.env['AUTHENTICATION_TOKEN'] 

  # JWT.authorization.call(auth_token)

  halt 403 if auth_token != 'GOOD_TOKEN'

  halt 500, 'No configuration found' unless request.path_info.start_with?('/configuration') || Configuration.last

  request.body.rewind
  @request_payload = JSON.parse(request.body.read).symbolize_keys
end

post '/' do
  transaction_params = transaction_params(@request_payload)

  transaction = Transaction.new(transaction_params)

  if transaction.save
    transaction.assert_score!

    [201, json({
      transaction_id: transaction.reload.transaction_id,
      recommendation: transaction.reload.recommendation
    })]
  else
    halt 412, "Invalid Parameters: #{transaction.errors.full_messages.join(', ')}"
  end
end

post '/configuration' do
  configuration_params = configuration_params(@request_payload)

  configuration = Configuration.last.dup || Configuration.new
  configuration.assign_attributes(configuration_params)

  if configuration.save
    configuration.to_json
  end
end

put '/chargeback' do
  transaction = Transaction.find_by(transaction_id: @request_payload[:transaction_id])

  transaction.chargeback = @request_payload[:chargeback]
  transaction.save!

  [200, json({
    transaction_id: transaction.reload.transaction_id,
    chargeback: transaction.reload.chargeback
  })]
end

def transaction_params(params)
  params.slice(:transaction_id, :merchant_id, :user_id, :card_number, :transaction_date, :transaction_amount, :device_id)
end

def configuration_params(params)
  params.slice(:start_nightly_hour, :end_nightly_hour, :max_nightly_amount, :max_transactions_in_row, :max_transactions_interval_minutes)
end