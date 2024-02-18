class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.string :card_number
      t.integer :transaction_id, index: true
      t.integer :merchant_id, index: true
      t.integer :user_id, index: true
      t.integer :device_id, index: true
      t.datetime :transaction_date
      t.decimal :transaction_amount

      t.boolean :chargeback, null: true
      t.integer :score, null: true

      t.timestamps null: false
    end
  end
end
