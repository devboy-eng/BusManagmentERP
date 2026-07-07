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
    msg_record = WhatsappMessage.create!(
      recipient: recipient,
      recipient_name: recipient.name,
      recipient_phone: recipient.phone,
      message_body: message,
      user: user,
      status: :queued
    )

    result = send_text_message(phone: recipient.phone, text: message)

    if result[:success]
      msg_record.update!(status: :sent, whatsapp_message_id: result[:message_id])
    else
      msg_record.update!(status: :failed, error_message: result[:error])
    end

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
    # Meta requires: lowercase, alphanumeric + underscores only for name
    meta_name = template.name.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")

    # Meta requires locale codes (en_US), not bare language codes (en)
    language = template.language || "en_US"
    language = "en_US" if language == "en"

    {
      name: meta_name,
      language: language,
      category: (template.category || "MARKETING").upcase,
      allow_category_change: true,
      components: build_components(template)
    }
  end

  def build_components(template)
    components = []

    # Header component
    case template.header_type
    when "text"
      components << { type: "HEADER", format: "TEXT", text: template.header_text } if template.header_text.present?
    when "image"
      components << { type: "HEADER", format: "IMAGE", example: { header_handle: [template.header_media_url] } } if template.header_media_url.present?
    when "video"
      components << { type: "HEADER", format: "VIDEO", example: { header_handle: [template.header_media_url] } } if template.header_media_url.present?
    when "document"
      components << { type: "HEADER", format: "DOCUMENT", example: { header_handle: [template.header_media_url] } } if template.header_media_url.present?
    end

    # Body component
    components << { type: "BODY", text: template.body }

    # Footer component
    components << { type: "FOOTER", text: template.footer } if template.footer.present?

    components
  end
end
