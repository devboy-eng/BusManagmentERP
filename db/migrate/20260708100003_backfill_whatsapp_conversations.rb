class BackfillWhatsappConversations < ActiveRecord::Migration[7.1]
  def up
    WhatsappMessage.where(whatsapp_conversation_id: nil).select(:recipient_phone).distinct.pluck(:recipient_phone).each do |phone|
      next if phone.blank?

      messages = WhatsappMessage.where(recipient_phone: phone, whatsapp_conversation_id: nil).order(:created_at)
      first_msg = messages.first
      last_msg = messages.last

      normalized_phone = phone.to_s.gsub(/\D/, "")
      normalized_phone = "91#{normalized_phone}" if normalized_phone.length == 10

      conversation = WhatsappConversation.find_or_create_by!(contact_phone: normalized_phone) do |conv|
        conv.contact_name = first_msg.recipient_name
        conv.contact_type = first_msg.recipient_type
        conv.contact_id = first_msg.recipient_id
        conv.last_message_body = last_msg.message_body
        conv.last_message_at = last_msg.created_at
        conv.unread_count = 0
      end

      messages.update_all(whatsapp_conversation_id: conversation.id, direction: "outgoing")
    end
  end

  def down
    WhatsappMessage.update_all(whatsapp_conversation_id: nil)
    WhatsappConversation.delete_all
  end
end
