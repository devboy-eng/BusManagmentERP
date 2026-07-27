class ModifyCustomersTable < ActiveRecord::Migration[7.1]
  def change
    remove_column :customers, :pan, :string if column_exists?(:customers, :pan)
    remove_column :customers, :trademark, :string if column_exists?(:customers, :trademark)

    add_column :customers, :customer_type, :integer, default: 0 unless column_exists?(:customers, :customer_type)
    add_column :customers, :company_name, :string unless column_exists?(:customers, :company_name)
    add_column :customers, :gst_number, :string unless column_exists?(:customers, :gst_number)
    add_column :customers, :alternate_phone, :string unless column_exists?(:customers, :alternate_phone)
    add_column :customers, :city, :string unless column_exists?(:customers, :city)
    add_column :customers, :state, :string unless column_exists?(:customers, :state)
    add_column :customers, :notes, :text unless column_exists?(:customers, :notes)
    add_reference :customers, :branch, foreign_key: true, null: true unless column_exists?(:customers, :branch_id)
  end
end
