class CreateBranches < ActiveRecord::Migration[7.1]
  def change
    create_table :branches do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :address
      t.string :city
      t.string :state, null: false
      t.string :state_code
      t.string :phone
      t.string :email
      t.string :gst_number
      t.boolean :is_default, default: false
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :branches, :code, unique: true
  end
end
