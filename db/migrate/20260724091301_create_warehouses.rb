class CreateWarehouses < ActiveRecord::Migration[7.1]
  def change
    create_table :warehouses do |t|
      t.string :name, null: false
      t.text :address
      t.string :contact_phone
      t.references :branch, foreign_key: true, null: true
      t.boolean :is_default, default: false
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
