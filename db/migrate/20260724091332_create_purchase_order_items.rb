class CreatePurchaseOrderItems < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_order_items do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.references :spare_part, null: false, foreign_key: true
      t.integer :ordered_quantity, null: false
      t.integer :received_quantity, default: 0
      t.decimal :unit_cost, precision: 10, scale: 2, null: false
      t.decimal :total_cost, precision: 10, scale: 2, default: 0
      t.timestamps
    end
  end
end
