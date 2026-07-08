class CreateWhatsappConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_conversations do |t|
      t.string :contact_phone, null: false
      t.string :contact_name
      t.string :contact_type
      t.integer :contact_id
      t.text :last_message_body
      t.datetime :last_message_at
      t.integer :unread_count, default: 0

      t.timestamps
    end

    add_index :whatsapp_conversations, :contact_phone, unique: true
    add_index :whatsapp_conversations, :last_message_at
    add_index :whatsapp_conversations, [:contact_type, :contact_id]
  end
end
