class CreateInspectionItems < ActiveRecord::Migration[7.1]
  def change
    create_table :inspection_items do |t|
      t.references :inspection, null: false, foreign_key: true
      t.string :area, null: false
      t.integer :condition, default: 0
      t.text :notes
      t.integer :sort_order, default: 0
      t.timestamps
    end
  end
end
