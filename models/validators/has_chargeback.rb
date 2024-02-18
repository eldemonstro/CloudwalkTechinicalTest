module Validators
  class HasChargeback
    def self.call(transaction, configuration)
      return 10 if Transaction.where(user_id: transaction.user_id, chargeback: true).any?

      0
    end
  end
end