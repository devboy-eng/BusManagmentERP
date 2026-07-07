class ProcessScheduledFollowUpsJob < ApplicationJob
  queue_as :default

  def perform
    FollowUp.due.find_each do |follow_up|
      process_follow_up(follow_up)
    end
  end

  private

  def process_follow_up(follow_up)
    service = WhatsappService.new
    result = service.send_text_message(phone: follow_up.lead.phone, text: follow_up.message)

    if result[:success]
      follow_up.update!(status: :sent, whatsapp_message_id: result[:message_id])

      WhatsappMessage.create!(
        recipient: follow_up.lead,
        recipient_name: follow_up.lead.name,
        recipient_phone: follow_up.lead.phone,
        message_body: follow_up.message,
        user: follow_up.user,
        status: :sent,
        whatsapp_message_id: result[:message_id]
      )
    else
      follow_up.update!(status: :failed, error_message: result[:error])
    end
  rescue => e
    follow_up.update!(status: :failed, error_message: e.message)
  end
end
