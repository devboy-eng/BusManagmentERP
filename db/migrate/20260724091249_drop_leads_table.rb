class DropLeadsTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :leads if table_exists?(:leads)
  end

  def down
    create_table :leads do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.text :address
      t.string :source
      t.integer :status, default: 0
      t.references :user, foreign_key: true
      t.text :notes
      t.timestamps
    end
  end
end
