class SendWhatsappTemplateJob < ApplicationJob
  queue_as :default
  retry_on WhatsappService::ApiError, wait: :polynomially_longer, attempts: 3

  def perform(recipient_type:, recipient_id:, template_id:, variables:, user_id:)
    recipient = recipient_type.constantize.find(recipient_id)
    template = WhatsappTemplate.find(template_id)
    user = User.find(user_id)
    service = WhatsappService.new
    service.send_template_and_log(recipient: recipient, template: template, variables: variables, user: user)
  end
end
