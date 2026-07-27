class CreateInventoryMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_movements do |t|
      t.references :spare_part, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :movement_type, default: 0
      t.string :reference_type
      t.integer :reference_id
      t.text :notes
      t.references :performed_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :inventory_movements, [:reference_type, :reference_id]
  end
end
