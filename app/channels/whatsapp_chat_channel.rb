class WhatsappChatChannel < ApplicationCable::Channel
  def subscribed
    if params[:conversation_id].present?
      conversation = WhatsappConversation.find(params[:conversation_id])
      stream_for conversation
    else
      stream_from "whatsapp_conversations"
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
