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

describe "post '/'" do
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

  def test_it_has_security
    create_configuration

    post '/', {}, { 'AUTHENTICATION_TOKEN' => 'WRONG_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    assert_equal 403, last_response.status
  end

  def test_it_receives_bad_payload
    create_configuration

    post '/', { bad_variable: 'bad_variable' }.to_json,
         { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    assert_equal 412, last_response.status
    assert_equal 'Invalid Parameters: transaction_id must be informed, ' \
                 'merchant_id must be informed, ' \
                 'user_id must be informed, ' \
                 'card_number must be informed, ' \
                 'transaction_date must be informed, ' \
                 'transaction_amount must be informed', last_response.body
  end

  def test_it_creates_a_transaction
    create_configuration

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => '2019-11-31T23:16:32.812632',
      'transaction_amount' => 373,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    assert_equal 201, last_response.status
    assert_equal 1, Transaction.count
  end

  def test_it_approves_a_transaction
    create_configuration

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => '2019-11-31T23:16:32.812632',
      'transaction_amount' => 373,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    expected_response = {
      'transaction_id' => 2_342_357,
      'recommendation' => 'approve'
    }

    assert_equal expected_response, JSON.parse(last_response.body)

    assert_equal 201, last_response.status
    assert_equal 1, Transaction.count
  end

  def test_it_too_many_transactions_in_row
    create_configuration
    create_too_many_transactions

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => DateTime.new(2019, 11, 11, 12, 12, 0, '+03:00').iso8601,
      'transaction_amount' => 373,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    expected_response = {
      'transaction_id' => 2_342_357,
      'recommendation' => 'refuse'
    }

    assert_equal expected_response, JSON.parse(last_response.body)

    assert_equal 201, last_response.status
    assert_equal 11, Transaction.count
  end

  def test_it_flags_close_too_many_transactions_in_row
    create_configuration
    create_close_too_many_transactions

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => DateTime.new(2019, 11, 11, 12, 12, 0, '+03:00').iso8601,
      'transaction_amount' => 373,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    expected_response = {
      'transaction_id' => 2_342_357,
      'recommendation' => 'flagged'
    }

    assert_equal expected_response, JSON.parse(last_response.body)

    assert_equal 201, last_response.status
    assert_equal 6, Transaction.count
  end

  def test_it_high_nightly_ammount
    create_configuration

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => DateTime.new(2019, 11, 11, 21, 0o0, 0o0, '+03:00').iso8601,
      'transaction_amount' => 1500,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    expected_response = {
      'transaction_id' => 2_342_357,
      'recommendation' => 'refuse'
    }

    assert_equal expected_response, JSON.parse(last_response.body)

    assert_equal 201, last_response.status
    assert_equal 1, Transaction.count
  end

  def test_it_low_nightly_ammount
    create_configuration

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => DateTime.new(2019, 11, 11, 21, 0o0, 0o0, '+03:00').iso8601,
      'transaction_amount' => 500,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    expected_response = {
      'transaction_id' => 2_342_357,
      'recommendation' => 'approve'
    }

    assert_equal expected_response, JSON.parse(last_response.body)

    assert_equal 201, last_response.status
    assert_equal 1, Transaction.count
  end

  def test_it_low_but_too_many_nightly_transactions
    create_configuration
    create_too_many_nightly_transactions

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => DateTime.new(2019, 11, 11, 20, 11, 0o0, '+03:00').iso8601,
      'transaction_amount' => 500,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    expected_response = {
      'transaction_id' => 2_342_357,
      'recommendation' => 'refuse'
    }

    assert_equal expected_response, JSON.parse(last_response.body)

    assert_equal 201, last_response.status
    assert_equal 11, Transaction.count
  end

  def test_it_has_chargeback
    create_configuration
    create_transaction_with_chargeback

    params = {
      'transaction_id' => 2_342_357,
      'merchant_id' => 29_744,
      'user_id' => 97_051,
      'card_number' => '434505******9116',
      'transaction_date' => '2019-11-31T23:16:32.812632',
      'transaction_amount' => 500,
      'device_id' => 285_475
    }

    post '/', params.to_json, { 'AUTHENTICATION_TOKEN' => 'GOOD_TOKEN', 'CONTENT_TYPE' => 'application/json' }

    expected_response = {
      'transaction_id' => 2_342_357,
      'recommendation' => 'refuse'
    }

    assert_equal expected_response, JSON.parse(last_response.body)

    assert_equal 201, last_response.status
    assert_equal 2, Transaction.count
  end
end

def create_too_many_transactions
  10.times do |index|
    params = {
      'transaction_id' => rand(1..2_342_357),
      'merchant_id' => rand(1..29_744),
      'user_id' => 97_051,
      'card_number' => "#{index + 434_505}******#{index + 9116}",
      'transaction_date' => DateTime.new(2019, 11, 11, 12, 1 + index, 0, '+03:00'),
      'transaction_amount' => rand(1..373),
      'device_id' => 285_475
    }

    Transaction.create(params)
  end
end

def create_close_too_many_transactions
  5.times do |index|
    params = {
      'transaction_id' => rand(1..2_342_357),
      'merchant_id' => rand(1..29_744),
      'user_id' => 97_051,
      'card_number' => "#{index + 434_505}******#{index + 9116}",
      'transaction_date' => DateTime.new(2019, 11, 11, 12, 1 + index, 0, '+03:00'),
      'transaction_amount' => rand(1..373),
      'device_id' => 285_475
    }

    Transaction.create(params)
  end
end

def create_too_many_nightly_transactions
  10.times do |index|
    params = {
      'transaction_id' => rand(1..2_342_357),
      'merchant_id' => rand(1..29_744),
      'user_id' => 97_051,
      'card_number' => "#{index + 434_505}******#{index + 9116}",
      'transaction_date' => DateTime.new(2019, 11, 11, 20, 1 + index, 0, '+03:00'),
      'transaction_amount' => rand(1..373),
      'device_id' => 285_475
    }

    Transaction.create(params)
  end
end

def create_transaction_with_chargeback
  params = {
    'transaction_id' => rand(1..2_342_357),
    'merchant_id' => rand(1..29_744),
    'user_id' => 97_051,
    'card_number' => '434505******9116',
    'transaction_date' => DateTime.new(2019, 11, 11, 12, 1, 0, '+03:00'),
    'transaction_amount' => rand(1..373),
    'device_id' => 285_475,
    'chargeback' => true
  }

  Transaction.create(params)
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
