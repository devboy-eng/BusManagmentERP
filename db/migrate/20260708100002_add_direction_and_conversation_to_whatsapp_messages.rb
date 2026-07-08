class AddDirectionAndConversationToWhatsappMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_messages, :direction, :string, default: "outgoing"
    add_reference :whatsapp_messages, :whatsapp_conversation, foreign_key: true, null: true
    add_index :whatsapp_messages, [:whatsapp_conversation_id, :created_at]
  end
end
