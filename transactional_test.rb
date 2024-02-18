require 'json'
require 'date'

require 'net/http'
require 'uri'

# Make a new configuration
def post_configuration
  # Configuration setup
  start_nightly_hour = 20
  end_nightly_hour = 6
  max_nightly_amount = 1000.00
  max_transactions_in_row = 10
  max_transactions_interval_minutes = 60

  configuration_body = {
    start_nightly_hour: DateTime.new(2020, 11, 11, start_nightly_hour, 0, 0, "+03:00"),
    end_nightly_hour: DateTime.new(2020, 11, 11, end_nightly_hour, 0, 0, "+03:00"),
    max_nightly_amount: max_nightly_amount,
    max_transactions_in_row: max_transactions_in_row,
    max_transactions_interval_minutes: max_transactions_interval_minutes
  }

  configuration_uri = URI.parse("http://0.0.0.0:3000/configuration")
  post_header = {'Content-Type': 'application/json', 'AUTHENTICATION_TOKEN': 'GOOD_TOKEN'}
  http = Net::HTTP.new(configuration_uri.host, configuration_uri.port)

  request = Net::HTTP::Post.new(configuration_uri.request_uri, post_header)
  request.body = configuration_body.to_json

  response = http.request(request)

  puts "New configuration posted" if response.code == "200"
end

post_configuration

# Get all lines
lines = File.open('transactional-sample.csv').read.split("\n")

# Get keys from first line
keys = lines.shift.split(',').map(&:to_sym)

# Turn all lines into payloads (separate chargebacks into a different payload)
transactions = lines.reverse.map do |line|
  values = line.split(',')

  base_payload = keys.zip(values).flatten.each_slice(2).to_h

  
  chargeback = {
    transaction_id: base_payload[:transaction_id],
    chargeback: base_payload[:has_cbk]
  }

  base_payload.delete(:has_cbk)

  [base_payload, chargeback]
end

# puts 'It\'s sorted' if payloads.sort { |a, b| DateTime.parse(a[0][:transaction_date]) <=> DateTime.parse(b[0][:transaction_date]) } == payloads.dup

transactions << "EOT"

daynumber = 0
index = 0
future_chargebacks = []
last_date = DateTime.parse(transactions[0][0][:transaction_date])
temp_last_date = nil

puts 'Posting'

responses_transactions = []
responses_chargeback = []

def post_transaction(transaction_payload)
  transaction_uri = URI.parse("http://0.0.0.0:3000/")
  post_header = {'Content-Type': 'application/json', 'AUTHENTICATION_TOKEN': 'GOOD_TOKEN'}
  http = Net::HTTP.new(transaction_uri.host, transaction_uri.port)

  request = Net::HTTP::Post.new(transaction_uri.request_uri, post_header)
  request.body = transaction_payload.to_json

  response = http.request(request)

  # print " Transaction #{transaction_payload[:transaction_id]} status #{response.code};"

  [response.code, response.body]
end

def post_chargeback(chargeback_payload)
  chargeback_uri = URI.parse("http://0.0.0.0:3000/chargeback")
  post_header = {'Content-Type': 'application/json', 'AUTHENTICATION_TOKEN': 'GOOD_TOKEN'}
  http = Net::HTTP.new(chargeback_uri.host, chargeback_uri.port)

  request = Net::HTTP::Put.new(chargeback_uri.request_uri, post_header)
  request.body = chargeback_payload.to_json

  response = http.request(request)

  # print " Chargeback #{chargeback_payload[:transaction_id]} status #{response.code};"

  [response.code, response.body]
end

# First post needs to be outside the loop to quickstart the loop
post_transaction(transactions[index][0])

# Set chargeback payload for a random number of days between 2 and 5
transactions[index][1][:days_offset] = 2 + rand(3)

# Adding this chargeback to the future chargebacks
future_chargebacks << transactions[index][1]

# Set the temporary last date to calculate last dates differences
temp_last_date = DateTime.parse(transactions[index][0][:transaction_date])

# Setting next so we don't fall into a infinite loop
index += 1

# transactions = [transaction_payload, chargeback_payload]
while future_chargebacks.any? do
  # Post Transactions until End of Transactions
  if transactions[index] != "EOT"
    responses_transactions << post_transaction(transactions[index][0])

    # Set chargeback payload for a random number of days between 2 and 5
    transactions[index][1][:days_offset] ||= 2 + rand(3)
    
    # Adding this chargeback to the future chargebacks
    future_chargebacks << transactions[index][1]

    # Set the temporary last date to calculate last dates differences
    temp_last_date = DateTime.parse(transactions[index][0][:transaction_date])

    # Setting next so we don't fall into a infinite loop
    index += 1
  end

  future_chargebacks.map do |cbk|
    if cbk[:days_offset] <= 0
      responses_chargeback << post_chargeback(cbk)
      cbk[:processed] = true
    end

    # Get numbers of days since last date
    days_passed = temp_last_date - last_date

    # Skip if no days have passed
    next cbk if days_passed == 0

    # Passing days for chargeback payload
    cbk[:days_offset] -= days_passed

    # Returning chargeback for the map
    cbk
  end

  # Removing processed chargebacks
  future_chargebacks.delete_if { |cbk| cbk[:processed] }
end

transactions_sucessfull = responses_transactions.map(&:first).all?("201")
chargeback_sucessfull = responses_chargeback.map(&:first).all?("200")

transactions_refused = responses_transactions.filter { |rt| JSON.parse(rt[1])["recommendation"] == "refuse" }.count.to_f / responses_transactions.count.to_f
transactions_flagged = responses_transactions.filter { |rt| JSON.parse(rt[1])["recommendation"] == "flagged" }.count.to_f / responses_transactions.count.to_f

puts "For #{responses_transactions.count} transaction, #{ transactions_sucessfull ? "All" : "Some" } were successfull, with #{ (transactions_refused * 100).round(2) }% being refused"
