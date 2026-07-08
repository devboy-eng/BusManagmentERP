class WhatsappService
  BASE_URL = "https://graph.facebook.com/v25.0".freeze

  class ApiError < StandardError; end

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
      error = response.parsed_response.dig("error", "message") || "Unknown API error"
      { success: false, error: error }
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

    { record: msg_record, result: result }
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
      query: { name: meta_name }
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
      query: { fields: "status" }
    )

    if response.success?
      new_status = response.parsed_response["status"]&.downcase
      template.update!(status: new_status) if new_status.present?
      { success: true, status: new_status }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to sync status"
      { success: false, error: error }
    end
  end

  def self.fetch_phone_numbers(access_token:, business_account_id:)
    response = HTTParty.get(
      "#{BASE_URL}/#{business_account_id}/phone_numbers",
      headers: { "Authorization" => "Bearer #{access_token}" },
      query: { fields: "id,display_phone_number,verified_name,quality_rating" }
    )

    if response.success?
      phones = response.parsed_response["data"] || []
      { success: true, phone_numbers: phones }
    else
      error = response.parsed_response.dig("error", "message") || "Failed to fetch phone numbers"
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

  def build_template_payload(template)
    # Meta requires: lowercase, alphanumeric + underscores only, max 512 chars
    meta_name = template.name.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")

    payload = {
      name: meta_name,
      language: template.language || "en",
      category: template.category || "marketing",
      allow_category_change: true,
      components: template.carousel? ? build_carousel_components(template) : build_components(template)
    }

    payload
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

      # Optional button
      if card["button_text"].present?
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
