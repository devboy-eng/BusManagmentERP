class CreateInvoiceLineItems < ActiveRecord::Migration[7.1]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :item_type, null: false
      t.string :description, null: false
      t.references :spare_part, foreign_key: true, null: true
      t.decimal :quantity, precision: 10, scale: 2, default: 1
      t.string :unit, default: "pcs"
      t.decimal :unit_price, precision: 10, scale: 2, default: 0
      t.decimal :total_price, precision: 10, scale: 2, default: 0
      t.string :hsn_code
      t.integer :sort_order, default: 0
      t.timestamps
    end
  end
end
