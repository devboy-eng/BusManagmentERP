class WhatsappService
  BASE_URL = "https://graph.facebook.com/v25.0".freeze

  class ApiError < StandardError; end
  class NonRetryableError < ApiError; end
  class RateLimitError < ApiError; end

  def initialize
    @setting = WhatsappSetting.first
    raise ApiError, "WhatsApp API is not configured" unless @setting&.active?

    @phone_number_id = @setting.phone_number_id
    @access_token = @setting.access_token
  end

  def send_text_message(phone:, text:)
    normalized = normalize_phone(phone)

    response = HTTParty.post(
      "#{BASE_URL}/#{@phone_number_id}/messages",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type" => "application/json"
      },
      body: {
        messaging_product: "whatsapp",
        to: normalized,
        type: "text",
        text: { body: text }
      }.to_json
    )

    if response.success?
      message_id = response.parsed_response.dig("messages", 0, "id")
      { success: true, message_id: message_id }
    else
      handle_api_error(response)
    end
  end

  def send_and_log(recipient:, message:, user:)
    conversation = WhatsappConversation.find_or_start(
      phone: recipient.phone,
      name: recipient.name,
      contact: recipient
    )

    msg_record = WhatsappMessage.create!(
      recipient: recipient,
      recipient_name: recipient.name,
      recipient_phone: recipient.phone,
      message_body: message,
      user: user,
      status: :queued,
      direction: "outgoing",
      whatsapp_conversation: conversation
    )

    result = send_text_message(phone: recipient.phone, text: message)

    if result[:success]
      msg_record.update!(status: :sent, whatsapp_message_id: result[:message_id])
    else
      msg_record.update!(status: :failed, error_message: result[:error])
    end

    conversation.update_last_message!(msg_record)

    # Broadcast to chat UI so it updates in real-time
    broadcast_new_message(conversation, msg_record)
    broadcast_conversation_update(conversation)

    { record: msg_record, result: result }
  end

  def send_media_message(phone:, type:, media_url:, caption: nil, filename: nil)
    normalized = normalize_phone(phone)

    media_object = { link: media_url }
    media_object[:caption] = caption if caption.present? && type.in?(%w[image video document])
    media_object[:filename] = filename if filename.present? && type == "document"

    response = HTTParty.post(
      "#{BASE_URL}/#{@phone_number_id}/messages",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type" => "application/json"
      },
      body: {
        messaging_product: "whatsapp",
        to: normalized,
        type: type,
        type => media_object
      }.to_json
    )

    if response.success?
      message_id = response.parsed_response.dig("messages", 0, "id")
      { success: true, message_id: message_id }
    else
      error = response.parsed_response.dig("error", "message") || "Unknown API error"
      { success: false, error: error }
    end
  end

  def send_and_log_media(recipient:, type:, media_url:, caption: nil, filename: nil, user:)
    conversation = WhatsappConversation.find_or_start(
      phone: recipient.phone,
      name: recipient.name,
      contact: recipient
    )

    mime_type = Rack::Mime.mime_type(File.extname(media_url.to_s), "application/octet-stream")

    msg_record = WhatsappMessage.create!(
      recipient: recipient,
      recipient_name: recipient.name,
      recipient_phone: recipient.phone,
      message_body: caption,
      message_type: type,
      media_url: media_url,
      media_mime_type: mime_type,
      media_filename: filename,
      media_caption: caption,
      user: user,
      status: :queued,
      direction: "outgoing",
      whatsapp_conversation: conversation
    )

    result = send_media_message(phone: recipient.phone, type: type, media_url: media_url, caption: caption, filename: filename)

    if result[:success]
      msg_record.update!(status: :sent, whatsapp_message_id: result[:message_id])
    else
      msg_record.update!(status: :failed, error_message: result[:error])
    end

    conversation.update_last_message!(msg_record)
    broadcast_new_message(conversation, msg_record)
    broadcast_conversation_update(conversation)

    { record: msg_record, result: result }
  end

  def send_reaction(phone:, message_id:, emoji:)
    normalized = normalize_phone(phone)

    response = HTTParty.post(
      "#{BASE_URL}/#{@phone_number_id}/messages",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type" => "application/json"
      },
      body: {
        messaging_product: "whatsapp",
        to: normalized,
        type: "reaction",
        reaction: {
          message_id: message_id,
          emoji: emoji
        }
      }.to_json
    )

    if response.success?
      api_message_id = response.parsed_response.dig("messages", 0, "id")
      { success: true, message_id: api_message_id }
    else
      error = response.parsed_response.dig("error", "message") || "Unknown API error"
      { success: false, error: error }
    end
  end

  def send_interactive_list(phone:, header: nil, body:, footer: nil, button_text: "Menu", sections:)
    normalized = normalize_phone(phone)

    interactive = {
      type: "list",
      body: { text: body },
      action: {
        button: button_text.truncate(20),
        sections: sections
      }
    }
    interactive[:header] = { type: "text", text: header } if header.present?
    interactive[:footer] = { text: footer } if footer.present?

    response = HTTParty.post(
      "#{BASE_URL}/#{@phone_number_id}/messages",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type" => "application/json"
      },
      body: {
        messaging_product: "whatsapp",
        to: normalized,
        type: "interactive",
        interactive: interactive
      }.to_json
    )

    if response.success?
      message_id = response.parsed_response.dig("messages", 0, "id")
      { success: true, message_id: message_id }
    else
      error = response.parsed_response.dig("error", "message") || "Unknown API error"
      { success: false, error: error }
    end
  end

  def download_media(media_id)
    # Step 1: Get media URL from Graph API
    response = HTTParty.get(
      "#{BASE_URL}/#{media_id}",
      headers: { "Authorization" => "Bearer #{@access_token}" }
    )

    return nil unless response.success?

    media_url = response.parsed_response["url"]
    mime_type = response.parsed_response["mime_type"]
    return nil unless media_url.present?

    { url: media_url, mime_type: mime_type }
  end

  def test_connection
    response = HTTParty.get(
      "#{BASE_URL}/#{@phone_number_id}",
      headers: { "Authorization" => "Bearer #{@access_token}" }
    )

    if response.success?
      { success: true, phone_number: response.parsed_response["display_phone_number"] }
    else
      error = response.parsed_response.dig("error", "message") || "Connection failed"
      { success: false, error: error }
    end
  end

  # --- Send Template Message ---

  def send_template_message(phone:, template:, variables: [])
    normalized = normalize_phone(phone)
    meta_name = template.name.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")

    template_payload = {
      name: meta_name,
      language: { code: template.language || "en" }
    }

    # Build components with variable substitutions
    components = []

    if template.category == "authentication"
      # Authentication templates: body param = OTP code
      otp_code = variables.first.to_s.presence || "000000"
      components << {
        type: "body",
        parameters: [{ type: "text", text: otp_code }]
      }
      components << {
        type: "button",
        sub_type: "url",
        index: "0",
        parameters: [{ type: "text", text: otp_code }]
      }
    else
      # Header variables (if header is text with {{1}})
      if template.header_type == "text" && template.header_text&.match?(/\{\{\d+\}\}/)
        header_vars = template.header_text.scan(/\{\{\d+\}\}/)
        components << {
          type: "header",
          parameters: header_vars.map.with_index { |_, i| { type: "text", text: variables[i].to_s.presence || "Sample" } }
        }
      end

      # Body variables ({{1}}, {{2}}, etc.)
      if template.body&.match?(/\{\{\d+\}\}/)
        body_vars = template.body.scan(/\{\{\d+\}\}/)
        header_var_count = (template.header_type == "text" && template.header_text&.match?(/\{\{\d+\}\}/)) ? template.header_text.scan(/\{\{\d+\}\}/).size : 0
        components << {
          type: "body",
          parameters: body_vars.map.with_index { |_, i| { type: "text", text: variables[header_var_count + i].to_s.presence || "Sample" } }
        }
      end
    end

    template_payload[:components] = components if components.any?

    request_body = {
      messaging_product: "whatsapp",
      to: normalized,
      type: "template",
      template: template_payload
    }

    Rails.logger.info("[WhatsApp Template Send] To: #{normalized}, Template: #{meta_name}, Payload: #{request_body.to_json}")

    response = HTTParty.post(
      "#{BASE_URL}/#{@phone_number_id}/messages",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type" => "application/json"
      },
      body: request_body.to_json
    )

    Rails.logger.info("[WhatsApp Template Send] Response: #{response.code} #{response.body}")

    if response.success?
      message_id = response.parsed_response.dig("messages", 0, "id")
      { success: true, message_id: message_id }
    else
      handle_api_error(response)
    end
  end

  def send_template_and_log(recipient:, template:, variables:, user:)
    conversation = WhatsappConversation.find_or_start(
      phone: recipient.phone,
      name: recipient.name,
      contact: recipient
    )

    # Build the display body by replacing variables
    display_body = template.body.dup
    variables.each_with_index { |val, i| display_body.gsub!("{{#{i + 1}}}", val.to_s) }

    msg_record = WhatsappMessage.create!(
      recipient: recipient,
      recipient_name: recipient.name,
      recipient_phone: recipient.phone,
      message_body: display_body,
      user: user,
      status: :queued,
      direction: "outgoing",
      whatsapp_conversation: conversation
    )

    result = send_template_message(phone: recipient.phone, template: template, variables: variables)

    if result[:success]
      msg_record.update!(status: :sent, whatsapp_message_id: result[:message_id])
    else
      msg_record.update!(status: :failed, error_message: result[:error])
    end

    conversation.update_last_message!(msg_record)

    # Broadcast to chat UI so it updates in real-time
    broadcast_new_message(conversation, msg_record)
    broadcast_conversation_update(conversation)

    { record: msg_record, result: result }
  end

  # --- Template Management (not auto-called) ---

  def create_template(template)
    response = HTTParty.post(
      "#{BASE_URL}/#{@setting.business_account_id}/message_templates",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type" => "application/json"
      },
      body: build_template_payload(template).to_json
    )

    if response.success?
      meta_id = response.parsed_response["id"]
      template.update!(meta_template_id: meta_id, status: "pending")
      { success: true, meta_template_id: meta_id }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to create template"
      { success: false, error: error }
    end
  end

  def delete_template(template)
    return { success: false, error: "No Meta template ID" } unless template.meta_template_id.present?

    meta_name = template.name.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")

    response = HTTParty.delete(
      "#{BASE_URL}/#{@setting.business_account_id}/message_templates",
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: { hsm_id: template.meta_template_id, name: meta_name }
    )

    if response.success?
      template.update!(meta_template_id: nil, status: "draft")
      { success: true }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to delete template"
      { success: false, error: error }
    end
  end

  def sync_status_from_meta(template)
    return { success: false, error: "No Meta template ID" } unless template.meta_template_id.present?

    response = HTTParty.get(
      "#{BASE_URL}/#{template.meta_template_id}",
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: { fields: "status,language,category,name" }
    )

    if response.success?
      data = response.parsed_response
      updates = {}
      updates[:status] = data["status"].downcase if data["status"].present?
      updates[:language] = data["language"] if data["language"].present?
      updates[:category] = data["category"].downcase if data["category"].present?
      template.update!(updates) if updates.any?
      { success: true, status: updates[:status] }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to sync status"
      { success: false, error: error }
    end
  end

  def fetch_all_templates_from_meta
    response = HTTParty.get(
      "#{BASE_URL}/#{@setting.business_account_id}/message_templates",
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: { fields: "id,name,status,language,category,components", limit: 100 }
    )

    unless response.success?
      error = response.parsed_response.dig("error", "message") || "Failed to fetch templates"
      return { success: false, error: error }
    end

    templates_data = response.parsed_response["data"] || []
    { success: true, templates: templates_data }
  end

  def self.fetch_phone_numbers(access_token:, business_account_id:)
    response = HTTParty.get(
      "#{BASE_URL}/#{business_account_id}/phone_numbers",
      headers: { "Authorization" => "Bearer #{access_token}" },
      query: { fields: "id,display_phone_number,verified_name,quality_rating,messaging_limit_tier,throughput" }
    )

    if response.success?
      phones = response.parsed_response["data"] || []
      { success: true, phone_numbers: phones }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to fetch phone numbers"
      { success: false, error: error }
    end
  end

  def self.fetch_phone_details(access_token:, phone_number_id:)
    response = HTTParty.get(
      "#{BASE_URL}/#{phone_number_id}",
      headers: { "Authorization" => "Bearer #{access_token}" },
      query: { fields: "display_phone_number,verified_name,name_status,status,code_verification_status,platform_type" }
    )

    if response.success?
      { success: true, data: response.parsed_response }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to fetch phone details"
      { success: false, error: error }
    end
  end

  def self.fetch_business_profile(access_token:, phone_number_id:)
    response = HTTParty.get(
      "#{BASE_URL}/#{phone_number_id}/whatsapp_business_profile",
      headers: { "Authorization" => "Bearer #{access_token}" },
      query: { fields: "about,description,address,email,websites,vertical,profile_picture_url" }
    )

    if response.success?
      profile = response.parsed_response.dig("data", 0) || {}
      { success: true, data: profile }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to fetch business profile"
      { success: false, error: error }
    end
  end

  def self.normalize_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")
    digits = "91#{digits}" if digits.length == 10
    digits
  end

  private

  def normalize_phone(phone)
    self.class.normalize_phone(phone)
  end

  NON_RETRYABLE_CODES = [
    131026, 131047, 131048, 131049, 131056,
    132000, 132001, 132005, 132012, 132015, 131031
  ].freeze
  RATE_LIMIT_CODES = [130429].freeze
  RETRYABLE_CODES = [131053].freeze

  def handle_api_error(response)
    error_data = response.parsed_response&.dig("error") || {}
    error_code = error_data["code"].to_i
    error_message = error_data["message"] || "Unknown API error (#{response.code})"

    if NON_RETRYABLE_CODES.include?(error_code)
      raise NonRetryableError, error_message
    elsif RATE_LIMIT_CODES.include?(error_code)
      raise RateLimitError, error_message
    elsif RETRYABLE_CODES.include?(error_code) || response.code >= 500
      raise ApiError, error_message
    else
      { success: false, error: error_message }
    end
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
    Rails.logger.error "[WhatsappService] Broadcast new_message failed: #{e.message}"
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
    Rails.logger.error "[WhatsappService] Broadcast conversation_update failed: #{e.message}"
  end

  def build_template_payload(template)
    # Meta requires: lowercase, alphanumeric + underscores only, max 512 chars
    meta_name = template.name.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")

    category = (template.category || "marketing").upcase

    components = if template.category == "authentication"
                   build_authentication_components(template)
                 elsif template.carousel?
                   build_carousel_components(template)
                 else
                   build_components(template)
                 end

    payload = {
      name: meta_name,
      language: template.language || "en",
      category: category,
      components: components
    }

    # allow_category_change not supported for authentication templates
    payload[:allow_category_change] = true unless template.category == "authentication"

    payload
  end

  def build_authentication_components(template)
    components = []

    # BODY — Meta auto-generates the OTP message text.
    # add_security_recommendation appends "Don't share this code."
    components << { type: "BODY", add_security_recommendation: true }

    # FOOTER — optional code expiration (extract number from footer text)
    if template.footer.present?
      minutes = template.footer.scan(/\d+/).first&.to_i
      components << { type: "FOOTER", code_expiration_minutes: minutes || 5 } if minutes
    end

    # BUTTONS — OTP copy-code button (required for authentication templates)
    components << {
      type: "BUTTONS",
      buttons: [{ type: "OTP", otp_type: "COPY_CODE" }]
    }

    components
  end

  def build_components(template)
    components = []

    # Header component
    case template.header_type
    when "text"
      if template.header_text.present?
        header = { type: "HEADER", format: "TEXT", text: template.header_text }
        # If header has variables like {{1}}, provide example values
        if template.header_text.match?(/\{\{.*?\}\}/)
          header[:example] = { header_text: [extract_example_values(template.header_text).first || "Sample"] }
        end
        components << header
      end
    when "image"
      components << { type: "HEADER", format: "IMAGE", example: { header_handle: [template.header_media_url] } } if template.header_media_url.present?
    when "video"
      components << { type: "HEADER", format: "VIDEO", example: { header_handle: [template.header_media_url] } } if template.header_media_url.present?
    when "document"
      components << { type: "HEADER", format: "DOCUMENT", example: { header_handle: [template.header_media_url] } } if template.header_media_url.present?
    end

    # Body component (required)
    body = { type: "BODY", text: template.body }
    # If body has variables like {{1}} or {{name}}, provide example values
    if template.body.match?(/\{\{.*?\}\}/)
      examples = extract_example_values(template.body)
      body[:example] = { body_text: [examples] }
    end
    components << body

    # Footer component (text only, max 60 chars, no variables)
    components << { type: "FOOTER", text: template.footer } if template.footer.present?

    # Buttons component
    btns = template.parsed_buttons
    if btns.any?
      meta_buttons = btns.map do |btn|
        case btn["type"]
        when "QUICK_REPLY"
          { type: "QUICK_REPLY", text: btn["text"] }
        when "URL"
          b = { type: "URL", text: btn["text"], url: btn["url"] }
          if btn["url"]&.match?(/\{\{\d+\}\}/)
            b[:example] = [btn["url"].gsub(/\{\{\d+\}\}/, "https://example.com/sample")]
          end
          b
        when "PHONE_NUMBER"
          { type: "PHONE_NUMBER", text: btn["text"], phone_number: btn["phone_number"] }
        when "COPY_CODE"
          { type: "COPY_CODE", text: btn["text"] }
        end
      end.compact
      components << { type: "BUTTONS", buttons: meta_buttons }
    end

    components
  end

  def build_carousel_components(template)
    components = []

    # Body component (the message text above the carousel)
    body = { type: "BODY", text: template.body }
    if template.body.match?(/\{\{.*?\}\}/)
      examples = extract_example_values(template.body)
      body[:example] = { body_text: [examples] }
    end
    components << body

    # Footer (optional)
    components << { type: "FOOTER", text: template.footer } if template.footer.present?

    # Carousel component with cards
    cards = template.parsed_carousel_cards
    carousel_cards = cards.map do |card|
      card_components = []

      # Each card must have a HEADER (image or video)
      if card["image_url"].present?
        card_components << {
          type: "HEADER",
          format: "IMAGE",
          example: { header_handle: [card["image_url"]] }
        }
      end

      # Each card must have a BODY
      card_body = { type: "BODY", text: card["body"] || "" }
      if card["body"]&.match?(/\{\{.*?\}\}/)
        examples = extract_example_values(card["body"])
        card_body[:example] = { body_text: [examples] }
      end
      card_components << card_body

      # Buttons — support new multi-button format or legacy single button
      card_buttons = card["buttons"]
      if card_buttons.is_a?(Array) && card_buttons.any?
        meta_btns = card_buttons.map do |btn|
          case btn["type"]
          when "QUICK_REPLY"
            { type: "QUICK_REPLY", text: btn["text"] }
          when "URL"
            b = { type: "URL", text: btn["text"], url: btn["url"] }
            if btn["url"]&.match?(/\{\{\d+\}\}/)
              b[:example] = [btn["url"].gsub(/\{\{\d+\}\}/, "https://example.com/sample")]
            end
            b
          when "PHONE_NUMBER"
            { type: "PHONE_NUMBER", text: btn["text"], phone_number: btn["phone_number"] }
          end
        end.compact
        card_components << { type: "BUTTONS", buttons: meta_btns } if meta_btns.any?
      elsif card["button_text"].present?
        # Legacy single button format
        buttons = []
        if card["button_url"].present?
          buttons << { type: "URL", text: card["button_text"], url: card["button_url"] }
        else
          buttons << { type: "QUICK_REPLY", text: card["button_text"] }
        end
        card_components << { type: "BUTTONS", buttons: buttons }
      end

      { components: card_components }
    end

    components << { type: "CAROUSEL", cards: carousel_cards }

    components
  end

  def extract_example_values(text)
    text.scan(/\{\{.*?\}\}/).map { |_| "Sample" }
  end
end
