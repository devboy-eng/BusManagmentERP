class CreateStockEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :stock_entries do |t|
      t.references :spare_part, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.integer :quantity, default: 0
      t.string :batch_number
      t.string :serial_number
      t.date :expiry_date
      t.date :warranty_expiry_date
      t.timestamps
    end
  end
end
