ENV['APP_ENV'] = 'test'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/hooks/default'
require 'database_cleaner/active_record'
require 'json'

require './transaction_approver_api'
require './models/configuration'

describe "post '/configuration'" do
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
  
  def test_it_creates_configuration
    params = {
      start_nightly_hour: DateTime.new(2020, 1, 1, 20, 0, 0, '+03:00'),
      end_nightly_hour: DateTime.new(2020, 1, 1, 06, 0, 0, '+03:00'),
      max_nightly_amount: 1000.00,
      max_transactions_in_row: 10,
      max_transactions_interval_minutes: 60
    }

    post '/configuration', params.to_json, { "AUTHENTICATION_TOKEN" => "GOOD_TOKEN", "CONTENT_TYPE" => "application/json"}

    payload = JSON.parse(last_response.body).symbolize_keys

    assert_equal "2020-01-01T17:00:00.000Z", payload[:start_nightly_hour]
    assert_equal "2020-01-01T03:00:00.000Z", payload[:end_nightly_hour]
    assert_equal "1000.0", payload[:max_nightly_amount]
    assert_equal 10, payload[:max_transactions_in_row]
    assert_equal 60, payload[:max_transactions_interval_minutes]

    assert_equal 200, last_response.status
    assert_equal 1, Configuration.count
  end

  def test_it_creates_a_new_config_on_top_of_a_old
    create_configuration
    
    params = {
      max_transactions_in_row: 15,
      max_transactions_interval_minutes: 90
    }

    post '/configuration', params.to_json, { "AUTHENTICATION_TOKEN" => "GOOD_TOKEN", "CONTENT_TYPE" => "application/json"}

    payload = JSON.parse(last_response.body).symbolize_keys

    assert_equal "2020-01-01T17:00:00.000Z", payload[:start_nightly_hour]
    assert_equal "2020-01-01T03:00:00.000Z", payload[:end_nightly_hour]
    assert_equal "1000.0", payload[:max_nightly_amount]
    assert_equal 15, payload[:max_transactions_in_row]
    assert_equal 90, payload[:max_transactions_interval_minutes]

    assert_equal 200, last_response.status
    assert_equal 2, Configuration.count
  end
end

def create_configuration
  Configuration.create(
    start_nightly_hour: DateTime.new(2020, 1, 1, 20, 0, 0, '+03:00'),
    end_nightly_hour: DateTime.new(2020, 1, 1, 06, 0, 0, '+03:00'),
    max_nightly_amount: 1000.00,
    max_transactions_in_row: 10,
    max_transactions_interval_minutes: 60
  )
end