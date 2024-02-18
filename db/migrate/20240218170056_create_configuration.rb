# frozen_string_literal: true

class CreateConfiguration < ActiveRecord::Migration[7.1]
  def change
    create_table :configurations do |t|
      t.datetime :start_nightly_hour, null: false
      t.datetime :end_nightly_hour, null: false
      t.decimal :max_nightly_amount, null: false

      t.integer :max_transactions_in_row, null: false
      t.integer :max_transactions_interval_minutes, null: false

      t.timestamps null: false
    end
  end
end
