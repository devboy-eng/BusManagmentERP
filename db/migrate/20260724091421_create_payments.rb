class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :payment_method, default: 0
      t.string :transaction_reference
      t.text :notes
      t.references :received_by, null: false, foreign_key: { to_table: :users }
      t.datetime :paid_at, null: false
      t.timestamps
    end
  end
end
