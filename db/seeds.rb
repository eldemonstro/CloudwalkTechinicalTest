# frozen_string_literal: true

Configuration.create(
  start_nightly_hour: DateTime.new(2020, 1, 1, 20, 0, 0, '+03:00'),
  end_nightly_hour: DateTime.new(2020, 1, 1, 0o6, 0, 0, '+03:00'),
  max_nightly_amount: 1000.00,
  max_transactions_in_row: 10,
  max_transactions_interval_minutes: 60
)

puts "Created #{Configuration.count} configuration"
