class CreateSpareParts < ActiveRecord::Migration[7.1]
  def change
    create_table :spare_parts do |t|
      t.string :part_number, null: false
      t.string :name, null: false
      t.text :description
      t.string :category
      t.string :brand
      t.string :compatible_makes
      t.string :unit, default: "pcs"
      t.decimal :selling_price, precision: 10, scale: 2, default: 0
      t.decimal :cost_price, precision: 10, scale: 2, default: 0
      t.integer :reorder_level, default: 5
      t.integer :current_stock, default: 0
      t.string :hsn_code
      t.integer :warranty_months, default: 0
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :spare_parts, :part_number, unique: true
    add_index :spare_parts, :category
    add_index :spare_parts, :current_stock
  end
end
