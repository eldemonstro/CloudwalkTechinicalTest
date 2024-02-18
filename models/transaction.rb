# frozen_string_literal: true

require './models/validators/has_chargeback'
require './models/validators/max_nightly_transactions'
require './models/validators/max_sequencial_transactions'

class Transaction < ActiveRecord::Base
  SCORE_VALIDATORS = [::Validators::MaxSequencialTransactions,
                      ::Validators::MaxNightlyTransaction,
                      ::Validators::HasChargeback].freeze

  validates :transaction_id,
            :merchant_id,
            :user_id,
            :card_number,
            :transaction_date,
            :transaction_amount,
            presence: { message: 'must be informed' }

  def assert_score!
    configuration = Configuration.last

    self.score = SCORE_VALIDATORS.sum { |validator| validator.call(self, configuration) }
    save!
  end

  def recommendation
    return 'approve' if score < 5
    return 'flagged' if score < 10

    'refuse'
  end

  def self.human_attribute_name(*attribute)
    super

    attribute[0]
  end
end
