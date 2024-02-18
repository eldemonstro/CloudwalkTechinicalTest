module Validators
  class MaxSequencialTransactions
    def self.call(transaction, configuration)
      date_range = (transaction.transaction_date - configuration.max_transactions_interval_minutes.minutes)..
                   (transaction.transaction_date)
      
      Transaction.where(user_id: transaction.user_id, transaction_date: date_range).count
    end
  end
end