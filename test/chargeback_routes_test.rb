# frozen_string_literal: true

ENV['APP_ENV'] = 'test'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/hooks/default'
require 'database_cleaner/active_record'
require 'json'

require './transaction_approver_api'
require './models/transaction'
require './models/configuration'

describe "put '/chargeback'" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  around(:each) do |&block|
    DatabaseCleaner.strategy = :transaction

    DatabaseCleaner.cleaning do
      super(&block)
    end
  end

  def test_it_sets_chargeback_on_transaction
    create_configuration
    create_transaction

    params = {
      'transaction_id' => 5000,
      'chargeback' => true
    }

    put '/chargeback', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    transaction = Transaction.find_by(transaction_id: 5000)

    assert_equal true, transaction.chargeback
    assert_equal 200, last_response.status
  end
end

def create_configuration
  Configuration.create(
    start_nightly_hour: DateTime.new(2020, 1, 1, 20, 0, 0, '+03:00'),
    end_nightly_hour: DateTime.new(2020, 1, 1, 0o6, 0, 0, '+03:00'),
    max_nightly_amount: 1000.00,
    max_transactions_in_row: 10,
    max_transactions_interval_minutes: 60
  )
end

def create_transaction
  params = {
    'transaction_id' => 5000,
    'merchant_id' => rand(1..29_744),
    'user_id' => 97_051,
    'card_number' => '434505******9116',
    'transaction_date' => DateTime.new(2019, 11, 11, 12, 1, 0, '+03:00'),
    'transaction_amount' => rand(1..373),
    'device_id' => 285_475
  }

  Transaction.create(params)
end
