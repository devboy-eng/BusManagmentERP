class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.text :address
      t.string :pan
      t.string :gst
      t.string :trademark
      t.integer :status
      t.integer :user_id

      t.timestamps
    end
  end
end
