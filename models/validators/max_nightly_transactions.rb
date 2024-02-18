# frozen_string_literal: true

module Validators
  class MaxNightlyTransaction
    def self.call(transaction, configuration)
      return 0 if configuration.max_nightly_amount > transaction.transaction_amount

      transaction_hour = transaction.transaction_date.hour

      if configuration.start_nightly_hour.hour >= transaction_hour &&
         transaction_hour >= configuration.end_nightly_hour.hour
        return 0
      end

      10
    end
  end
end
