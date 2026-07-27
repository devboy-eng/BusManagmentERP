class CreateServiceReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :service_reminders do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :reminder_type
      t.date :due_date
      t.integer :odometer_due_at
      t.integer :status, default: 0
      t.string :whatsapp_message_id
      t.datetime :sent_at
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end
    add_index :service_reminders, :due_date
    add_index :service_reminders, :status
  end
end
