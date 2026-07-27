class EstimateNotificationService
  def initialize(job_card, estimate)
    @job_card = job_card
    @estimate = estimate
  end

  def send_approval_link
    return unless @job_card.customer&.phone.present?

    token = @job_card.customer_approval_token
    base_url = ENV.fetch("APP_BASE_URL", "http://localhost:3009")
    approval_url = "#{base_url}/approve/#{token}"

    message = "Hello #{@job_card.customer.name},\n\n" \
              "Your vehicle #{@job_card.vehicle.registration_number} service estimate is ready.\n" \
              "Estimate #: #{@estimate.estimate_number}\n" \
              "Total: Rs.#{@estimate.grand_total}\n\n" \
              "Please review and approve: #{approval_url}\n\n" \
              "- Bus Service Pro"

    begin
      whatsapp_service = WhatsappService.new
      whatsapp_service.send_and_log(to: @job_card.customer.phone, body: message, contact: @job_card.customer)
    rescue => e
      Rails.logger.error "WhatsApp notification failed: #{e.message}"
    end

    @job_card.update(status: :estimate_sent) if @job_card.estimate_created?
  end
end
