class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.references :job_card, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.decimal :labor_total, precision: 10, scale: 2, default: 0
      t.decimal :parts_total, precision: 10, scale: 2, default: 0
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.string :tax_type, default: "cgst_sgst"
      t.decimal :cgst_rate, precision: 5, scale: 2, default: 9.0
      t.decimal :sgst_rate, precision: 5, scale: 2, default: 9.0
      t.decimal :igst_rate, precision: 5, scale: 2, default: 18.0
      t.decimal :cgst_amount, precision: 10, scale: 2, default: 0
      t.decimal :sgst_amount, precision: 10, scale: 2, default: 0
      t.decimal :igst_amount, precision: 10, scale: 2, default: 0
      t.decimal :total_tax, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :grand_total, precision: 10, scale: 2, default: 0
      t.integer :status, default: 0
      t.text :notes
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.datetime :sent_at
      t.timestamps
    end
    add_index :invoices, :invoice_number, unique: true
  end
end
