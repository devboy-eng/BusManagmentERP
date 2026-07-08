class WhatsappWebhooksController < ActionController::Base
  skip_forgery_protection

  def verify
    mode = params["hub.mode"]
    token = params["hub.verify_token"]
    challenge = params["hub.challenge"]

    setting = WhatsappSetting.first

    if mode == "subscribe" && setting&.verify_token == token
      render plain: challenge, status: :ok
    else
      head :forbidden
    end
  end

  def receive
    payload = request.body.read
    setting = WhatsappSetting.first

    # Verify signature if app_secret is configured
    if setting&.app_secret.present?
      signature = request.headers["X-Hub-Signature-256"]
      unless valid_signature?(payload, signature, setting.app_secret)
        head :unauthorized
        return
      end
    end

    data = JSON.parse(payload) rescue {}

    Rails.logger.info "[WhatsApp Webhook] Received payload keys: #{data.keys}"

    process_statuses(data)
    process_incoming_messages(data)

    head :ok
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Unhandled error: #{e.class}: #{e.message}"
    head :ok
  end

  private

  def valid_signature?(payload, signature, app_secret)
    return false unless signature.present?

    expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", app_secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def process_statuses(data)
    entries = data.dig("entry") || []

    entries.each do |entry|
      changes = entry["changes"] || []
      changes.each do |change|
        statuses = change.dig("value", "statuses") || []
        statuses.each do |status|
          update_message_status(status)
        end
      end
    end
  end

  def update_message_status(status)
    whatsapp_id = status["id"]
    new_status = status["status"]

    return unless whatsapp_id.present? && new_status.present?

    status_map = {
      "sent" => :sent,
      "delivered" => :delivered,
      "read" => :read,
      "failed" => :failed
    }

    mapped = status_map[new_status]
    return unless mapped

    message = WhatsappMessage.find_by(whatsapp_message_id: whatsapp_id)
    return unless message

    if mapped == :failed
      error_info = status.dig("errors", 0, "title") || "Unknown error"
      message.update(status: mapped, error_message: error_info)
    else
      message.update(status: mapped)
    end

    # Broadcast status update to chat UI
    broadcast_message_status_update(message)
  end

  def process_incoming_messages(data)
    entries = data.dig("entry") || []

    entries.each do |entry|
      changes = entry["changes"] || []
      changes.each do |change|
        value = change["value"] || {}
        messages = value["messages"] || []
        contacts = value["contacts"] || []

        Rails.logger.info "[WhatsApp Webhook] Found #{messages.size} incoming message(s)" if messages.any?

        messages.each do |msg|
          process_single_incoming_message(msg, contacts)
        end
      end
    end
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Error processing incoming messages: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  def process_single_incoming_message(msg, contacts)
    Rails.logger.info "[WhatsApp Webhook] Processing message type=#{msg["type"]} id=#{msg["id"]} from=#{msg["from"]}"

    return unless msg["type"] == "text"

    whatsapp_id = msg["id"]
    return if whatsapp_id.blank?

    # Deduplicate
    if WhatsappMessage.exists?(whatsapp_message_id: whatsapp_id)
      Rails.logger.info "[WhatsApp Webhook] Duplicate message #{whatsapp_id}, skipping"
      return
    end

    sender_phone = msg["from"]
    text_body = msg.dig("text", "body")
    return if sender_phone.blank? || text_body.blank?

    # Get contact name from webhook payload
    contact_info = contacts&.find { |c| c["wa_id"] == sender_phone }
    sender_name = contact_info&.dig("profile", "name")

    # Match to Customer or Lead
    contact = WhatsappConversation.find_contact_by_phone(sender_phone)

    # Find or create conversation
    conversation = WhatsappConversation.find_or_start(
      phone: sender_phone,
      name: sender_name,
      contact: contact
    )

    # Create incoming message
    message = WhatsappMessage.create!(
      recipient_phone: sender_phone,
      recipient_name: sender_name || contact&.name,
      recipient: contact,
      message_body: text_body,
      direction: "incoming",
      whatsapp_conversation: conversation,
      whatsapp_message_id: whatsapp_id,
      status: :delivered
    )

    Rails.logger.info "[WhatsApp Webhook] Created incoming message #{message.id} in conversation #{conversation.id}"

    # Update conversation
    conversation.update_last_message!(message)
    conversation.increment_unread!

    # Broadcast new message to conversation channel
    broadcast_new_message(conversation, message)

    # Broadcast conversation list update
    broadcast_conversation_update(conversation)

    # Send read receipt back to WhatsApp
    send_read_receipt(whatsapp_id)
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Error processing message #{msg["id"]}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
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
  rescue Exception => e
    Rails.logger.error "[WhatsApp Webhook] Broadcast new_message failed: #{e.message}"
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
  rescue Exception => e
    Rails.logger.error "[WhatsApp Webhook] Broadcast conversation_update failed: #{e.message}"
  end

  def broadcast_message_status_update(message)
    return unless message.whatsapp_conversation

    html = ApplicationController.renderer.render(
      partial: "whatsapp_chats/message",
      locals: { message: message }
    )

    WhatsappChatChannel.broadcast_to(
      message.whatsapp_conversation,
      { type: "message_status", message_id: message.id, html: html }
    )
  rescue Exception => e
    Rails.logger.error "[WhatsApp Webhook] Broadcast message_status failed: #{e.message}"
  end

  def send_read_receipt(message_id)
    setting = WhatsappSetting.first
    return unless setting&.active?

    HTTParty.post(
      "https://graph.facebook.com/v25.0/#{setting.phone_number_id}/messages",
      headers: {
        "Authorization" => "Bearer #{setting.access_token}",
        "Content-Type" => "application/json"
      },
      body: {
        messaging_product: "whatsapp",
        status: "read",
        message_id: message_id
      }.to_json
    )
  rescue => e
    Rails.logger.error("Failed to send read receipt: #{e.message}")
  end
end
