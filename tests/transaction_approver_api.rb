ENV['APP_ENV'] = 'test'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/spec'
require './transaction_approver_api'

describe 'Examples' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_it_has_security
    get '/', {}, { "AUTHENTICATION_TOKEN" => "WRONG_TOKEN" }

    assert_equal 403, last_response.status
  end
end