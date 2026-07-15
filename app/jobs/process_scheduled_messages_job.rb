class ProcessScheduledMessagesJob < ApplicationJob
  queue_as :default

  def perform
    ScheduledMessage.due.find_each do |scheduled|
      process_scheduled_message(scheduled)
    end
  end

  private

  def process_scheduled_message(scheduled)
    conversation = scheduled.whatsapp_conversation
    return scheduled.update!(status: :failed, error_message: "Conversation not found") unless conversation

    service = WhatsappService.new
    result = service.send_text_message(phone: conversation.contact_phone, text: scheduled.message_body)

    if result[:success]
      scheduled.update!(status: :sent, whatsapp_message_id: result[:message_id])

      message = WhatsappMessage.create!(
        recipient_phone: conversation.contact_phone,
        recipient_name: conversation.contact_name,
        recipient: conversation.contact,
        message_body: scheduled.message_body,
        user: scheduled.user,
        direction: "outgoing",
        whatsapp_conversation: conversation,
        whatsapp_message_id: result[:message_id],
        status: :sent,
        message_type: "text"
      )

      conversation.update_last_message!(message)

      # Broadcast to chat UI
      broadcast_new_message(conversation, message)
      broadcast_conversation_update(conversation)
    else
      scheduled.update!(status: :failed, error_message: result[:error])
    end
  rescue => e
    scheduled.update!(status: :failed, error_message: e.message)
  end

  def broadcast_new_message(conversation, message)
    html = ApplicationController.renderer.render(
      partial: "whatsapp_chats/message",
      locals: { message: message }
    )

    WhatsappChatChannel.broadcast_to(
      conversation,
      { type: "new_message", html: html }
    )
  rescue => e
    Rails.logger.error "[ProcessScheduledMessagesJob] Broadcast new_message failed: #{e.message}"
  end

  def broadcast_conversation_update(conversation)
    html = ApplicationController.renderer.render(
      partial: "whatsapp_chats/conversation",
      locals: { conversation: conversation, selected: false }
    )

    ActionCable.server.broadcast(
      "whatsapp_conversations",
      { type: "conversation_update", conversation_id: conversation.id, html: html }
    )
  rescue => e
    Rails.logger.error "[ProcessScheduledMessagesJob] Broadcast conversation_update failed: #{e.message}"
  end
end
