# frozen_string_literal: true

module Validators
  class HasChargeback
    def self.call(transaction, _configuration)
      return 10 if Transaction.where(user_id: transaction.user_id, chargeback: true).any?

      0
    end
  end
end
