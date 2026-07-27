class CreateTechnicians < ActiveRecord::Migration[7.1]
  def change
    create_table :technicians do |t|
      t.references :user, foreign_key: true, null: true
      t.references :branch, foreign_key: true, null: true
      t.string :name, null: false
      t.string :phone
      t.string :employee_id
      t.string :specialization
      t.decimal :hourly_rate, precision: 8, scale: 2, default: 0
      t.integer :status, default: 0
      t.date :joined_on
      t.text :notes
      t.timestamps
    end
    add_index :technicians, :employee_id, unique: true
  end
end
