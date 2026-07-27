class CreatePurchaseOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_orders do |t|
      t.string :po_number, null: false
      t.references :supplier, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.integer :status, default: 0
      t.date :expected_delivery_date
      t.date :received_date
      t.text :notes
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :purchase_orders, :po_number, unique: true
  end
end
