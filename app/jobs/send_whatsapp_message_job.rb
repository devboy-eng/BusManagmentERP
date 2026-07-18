class SendWhatsappMessageJob < ApplicationJob
  queue_as :default
  discard_on(WhatsappService::NonRetryableError) do |job, error|
    Rails.logger.warn "[SendWhatsappMessageJob] Discarded #{job.arguments.inspect}: #{error.message}"
  end
  retry_on WhatsappService::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on WhatsappService::ApiError, wait: :polynomially_longer, attempts: 3

  def perform(recipient_type:, recipient_id:, message:, user_id:)
    recipient = recipient_type.constantize.find(recipient_id)
    user = User.find(user_id)
    service = WhatsappService.new
    service.send_and_log(recipient: recipient, message: message, user: user)
  end
end
