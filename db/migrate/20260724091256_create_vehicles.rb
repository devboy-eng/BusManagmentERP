class CreateVehicles < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicles do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :registration_number, null: false
      t.string :vin
      t.string :make, null: false
      t.string :model
      t.integer :year_of_manufacture
      t.string :engine_number
      t.string :chassis_number
      t.string :fuel_type
      t.integer :seating_capacity
      t.integer :current_odometer
      t.string :color
      t.string :insurance_provider
      t.string :insurance_policy_number
      t.date :insurance_expiry_date
      t.date :fitness_certificate_expiry
      t.date :permit_expiry_date
      t.date :puc_expiry_date
      t.text :notes
      t.integer :status, default: 0
      t.timestamps
    end
    add_index :vehicles, :registration_number, unique: true
  end
end
