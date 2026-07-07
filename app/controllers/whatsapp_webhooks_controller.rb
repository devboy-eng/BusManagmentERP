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

    process_statuses(data)

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
  end
end
