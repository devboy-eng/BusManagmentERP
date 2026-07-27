class CreateServiceTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :service_types do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :base_labor_charge, precision: 10, scale: 2, default: 0
      t.integer :estimated_hours
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      t.timestamps
    end
  end
end
