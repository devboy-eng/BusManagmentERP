class CreateSuppliers < ActiveRecord::Migration[7.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_person
      t.string :phone
      t.string :email
      t.text :address
      t.string :gst_number
      t.text :notes
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
