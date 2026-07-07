class CreateWhatsappMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_messages do |t|
      t.string :recipient_type
      t.integer :recipient_id
      t.string :recipient_name
      t.string :recipient_phone
      t.text :message_body
      t.string :whatsapp_message_id
      t.integer :status, default: 0
      t.text :error_message
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :whatsapp_messages, [:recipient_type, :recipient_id]
  end
end
