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

  # Meta requires 200 OK on EVERY webhook call — non-200 responses
  # cause retries and eventually webhook deactivation + quality drops.
  def receive
    payload = request.body.read
    setting = WhatsappSetting.first

    # Verify signature if app_secret is configured
    if setting&.app_secret.present?
      signature = request.headers["X-Hub-Signature-256"]
      unless valid_signature?(payload, signature, setting.app_secret)
        Rails.logger.warn "[WhatsApp Webhook] Invalid signature — ignoring payload"
        head :ok
        return
      end
    end

    data = JSON.parse(payload) rescue {}

    Rails.logger.info "[WhatsApp Webhook] Received payload keys: #{data.keys}"

    process_statuses(data)
    process_incoming_messages(data)

    head :ok
  rescue Exception => e
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
  rescue Exception => e
    Rails.logger.error "[WhatsApp Webhook] Error processing statuses: #{e.class}: #{e.message}"
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

    broadcast_message_status_update(message)

    # Update campaign contact status if this message belongs to a campaign
    update_campaign_contact_status(whatsapp_id, mapped)
  end

  def update_campaign_contact_status(whatsapp_id, status)
    contact = FollowUpCampaignContact.find_by(whatsapp_message_id: whatsapp_id)
    return unless contact

    case status
    when :sent
      contact.update!(status: :sent, sent_at: Time.current) if contact.queued? || contact.accepted?
    when :delivered
      contact.update!(status: :delivered, delivered_at: Time.current) unless contact.read?
    when :read
      contact.update!(status: :read, read_at: Time.current)
    when :failed
      contact.update!(status: :failed)
    end

    contact.follow_up_campaign.update_counts!
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Campaign contact status update error: #{e.message}"
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
  rescue Exception => e
    Rails.logger.error "[WhatsApp Webhook] Error processing incoming messages: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  def process_single_incoming_message(msg, contacts)
    msg_type = msg["type"]
    Rails.logger.info "[WhatsApp Webhook] Processing message type=#{msg_type} id=#{msg["id"]} from=#{msg["from"]}"

    supported_types = %w[text image video audio document reaction button interactive]
    return unless msg_type.in?(supported_types)

    whatsapp_id = msg["id"]
    return if whatsapp_id.blank?

    # Deduplicate — Meta may send the same message multiple times
    if WhatsappMessage.exists?(whatsapp_message_id: whatsapp_id)
      Rails.logger.info "[WhatsApp Webhook] Duplicate message #{whatsapp_id}, skipping"
      return
    end

    sender_phone = msg["from"]
    return if sender_phone.blank?

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

    # Handle reaction messages separately (they don't create a new bubble, they annotate an existing message)
    if msg_type == "reaction"
      process_reaction(msg, conversation, sender_phone, sender_name, contact, whatsapp_id)
      return
    end

    # Extract message content based on type
    message_attrs = extract_message_attrs(msg, msg_type)
    return if message_attrs.nil?

    # Create incoming message
    message = WhatsappMessage.create!(
      recipient_phone: sender_phone,
      recipient_name: sender_name || contact&.name,
      recipient: contact,
      message_body: message_attrs[:body],
      message_type: message_attrs[:message_type],
      media_url: message_attrs[:media_url],
      media_mime_type: message_attrs[:media_mime_type],
      media_filename: message_attrs[:media_filename],
      media_caption: message_attrs[:media_caption],
      context_message_id: message_attrs[:context_message_id],
      direction: "incoming",
      whatsapp_conversation: conversation,
      whatsapp_message_id: whatsapp_id,
      status: :delivered
    )

    Rails.logger.info "[WhatsApp Webhook] Created incoming message #{message.id} (type=#{message_attrs[:message_type]}) in conversation #{conversation.id}"

    # Update conversation
    conversation.update_last_message!(message)
    conversation.increment_unread!

    # Broadcast to chat UI
    broadcast_new_message(conversation, message)
    broadcast_conversation_update(conversation)

    # Send read receipt so sender sees blue ticks
    send_read_receipt(whatsapp_id)

    # Check for opt-out/opt-in keywords before any auto-reply processing
    if msg_type == "text" && message_attrs[:body].present?
      return if check_opt_out_or_in(message_attrs[:body], conversation, sender_phone)
    end

    # Check if this is a menu item selection (list_reply)
    if message_attrs[:_list_reply_id].present?
      check_menu_reply(message_attrs[:_list_reply_id], conversation, sender_phone)
    # Auto-reply + menu trigger check (for text messages)
    elsif msg_type == "text" && message_attrs[:body].present?
      check_menu_trigger(message_attrs[:body], conversation, sender_phone) ||
        check_auto_reply(message_attrs[:body], conversation, sender_phone)
    end
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Error processing message #{msg["id"]}: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  def extract_message_attrs(msg, msg_type)
    case msg_type
    when "text"
      body = msg.dig("text", "body")
      return nil if body.blank?
      { body: body, message_type: "text" }
    when "image", "video", "audio", "document"
      media_data = msg[msg_type] || {}
      media_url = resolve_media_url(media_data["id"])
      {
        body: media_data["caption"],
        message_type: msg_type,
        media_url: media_url,
        media_mime_type: media_data["mime_type"],
        media_filename: media_data["filename"],
        media_caption: media_data["caption"]
      }
    when "button"
      button_text = msg.dig("button", "text")
      return nil if button_text.blank?
      {
        body: button_text,
        message_type: "button_reply",
        context_message_id: msg.dig("context", "id")
      }
    when "interactive"
      interactive_type = msg.dig("interactive", "type")
      reply = msg.dig("interactive", "button_reply") || msg.dig("interactive", "list_reply")
      return nil if reply.nil?
      {
        body: reply["title"],
        message_type: "button_reply",
        context_message_id: msg.dig("context", "id"),
        _list_reply_id: (interactive_type == "list_reply" ? reply["id"] : nil)
      }
    else
      nil
    end
  end

  def process_reaction(msg, conversation, sender_phone, sender_name, contact, whatsapp_id)
    reaction_data = msg["reaction"] || {}
    target_message_id = reaction_data["message_id"]
    emoji = reaction_data["emoji"]

    return if target_message_id.blank?

    # Find the target message
    target_message = WhatsappMessage.find_by(whatsapp_message_id: target_message_id)

    # Create a reaction message record
    message = WhatsappMessage.create!(
      recipient_phone: sender_phone,
      recipient_name: sender_name || contact&.name,
      recipient: contact,
      message_type: "reaction",
      reaction_emoji: emoji,
      context_message_id: target_message_id,
      direction: "incoming",
      whatsapp_conversation: conversation,
      whatsapp_message_id: whatsapp_id,
      status: :delivered
    )

    # Broadcast to chat UI
    broadcast_new_message(conversation, message)
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Error processing reaction: #{e.class}: #{e.message}"
  end

  def resolve_media_url(media_id)
    return nil if media_id.blank?
    service = WhatsappService.new
    result = service.download_media(media_id)
    result&.dig(:url)
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Failed to resolve media URL for #{media_id}: #{e.message}"
    nil
  end

  OPT_OUT_KEYWORDS = %w[STOP UNSUBSCRIBE].freeze
  OPT_IN_KEYWORDS = %w[START SUBSCRIBE].freeze

  def check_opt_out_or_in(text, conversation, sender_phone)
    normalized_text = text.strip.upcase

    # Also handle "OPT OUT" and "OPT IN" as multi-word keywords
    is_opt_out = OPT_OUT_KEYWORDS.include?(normalized_text) || normalized_text == "OPT OUT"
    is_opt_in = OPT_IN_KEYWORDS.include?(normalized_text) || normalized_text == "OPT IN"

    return false unless is_opt_out || is_opt_in

    contact = conversation.contact
    return false unless contact.is_a?(Lead) || contact.is_a?(Customer)

    if is_opt_out
      contact.update!(whatsapp_opt_out: true)
      reply_text = "You have been unsubscribed from WhatsApp messages. Reply START to re-subscribe."
      Rails.logger.info "[WhatsApp Webhook] Contact #{contact.class}##{contact.id} opted out (phone: #{sender_phone})"
    else
      contact.update!(whatsapp_opt_out: false)
      reply_text = "You have been re-subscribed to WhatsApp messages. Reply STOP to unsubscribe."
      Rails.logger.info "[WhatsApp Webhook] Contact #{contact.class}##{contact.id} opted in (phone: #{sender_phone})"
    end

    # Send confirmation reply
    service = WhatsappService.new
    result = service.send_text_message(phone: sender_phone, text: reply_text)

    if result[:success]
      reply_message = WhatsappMessage.create!(
        recipient_phone: sender_phone,
        message_body: reply_text,
        direction: "outgoing",
        whatsapp_conversation: conversation,
        whatsapp_message_id: result[:message_id],
        status: :sent,
        message_type: "text"
      )

      conversation.update_last_message!(reply_message)
      broadcast_new_message(conversation, reply_message)
      broadcast_conversation_update(conversation)
    end

    true
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Opt-out/in error: #{e.class}: #{e.message}"
    false
  end

  def check_menu_trigger(text, conversation, sender_phone)
    menu = WhatsappMenu.find_by_trigger(text)
    return false unless menu

    service = WhatsappService.new
    result = service.send_interactive_list(
      phone: sender_phone,
      header: menu.header_text,
      body: menu.body_text,
      footer: menu.footer_text,
      button_text: menu.button_text,
      sections: menu.api_sections
    )

    if result[:success]
      # Build display body showing the menu was sent
      display = "📋 #{menu.name}\n#{menu.body_text}"

      reply_message = WhatsappMessage.create!(
        recipient_phone: sender_phone,
        message_body: display,
        direction: "outgoing",
        whatsapp_conversation: conversation,
        whatsapp_message_id: result[:message_id],
        status: :sent,
        message_type: "text"
      )

      conversation.update_last_message!(reply_message)
      broadcast_new_message(conversation, reply_message)
      broadcast_conversation_update(conversation)
    end

    true
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Menu trigger error: #{e.class}: #{e.message}"
    false
  end

  def check_menu_reply(item_id, conversation, sender_phone)
    # Search all active menus for the item
    WhatsappMenu.active.find_each do |menu|
      reply_text = menu.reply_for_item(item_id)
      next unless reply_text.present?

      service = WhatsappService.new
      result = service.send_text_message(phone: sender_phone, text: reply_text)

      if result[:success]
        reply_message = WhatsappMessage.create!(
          recipient_phone: sender_phone,
          message_body: reply_text,
          direction: "outgoing",
          whatsapp_conversation: conversation,
          whatsapp_message_id: result[:message_id],
          status: :sent,
          message_type: "text"
        )

        conversation.update_last_message!(reply_message)
        broadcast_new_message(conversation, reply_message)
        broadcast_conversation_update(conversation)
      end

      return
    end
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Menu reply error: #{e.class}: #{e.message}"
  end

  def check_auto_reply(text, conversation, sender_phone)
    rule = AutoReplyRule.match_incoming(text, conversation)
    return unless rule

    service = WhatsappService.new
    result = service.send_text_message(phone: sender_phone, text: rule.reply_body)

    if result[:success]
      reply_message = WhatsappMessage.create!(
        recipient_phone: sender_phone,
        message_body: rule.reply_body,
        direction: "outgoing",
        whatsapp_conversation: conversation,
        whatsapp_message_id: result[:message_id],
        status: :sent,
        message_type: "text"
      )

      conversation.update_last_message!(reply_message)
      broadcast_new_message(conversation, reply_message)
      broadcast_conversation_update(conversation)
    end
  rescue => e
    Rails.logger.error "[WhatsApp Webhook] Auto-reply error: #{e.class}: #{e.message}"
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
    Rails.logger.error "[WhatsApp Webhook] Failed to send read receipt: #{e.message}"
  end
end
