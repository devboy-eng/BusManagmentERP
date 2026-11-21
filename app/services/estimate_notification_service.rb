class EstimateNotificationService
  def initialize(job_card, estimate)
    @job_card = job_card
    @estimate = estimate
  end

  # Send estimate approval link to customer via WhatsApp
  def send_approval_link
    return unless @job_card.customer&.phone.present?

    token = @job_card.customer_approval_token
    base_url = ENV.fetch("APP_BASE_URL", "http://localhost:3009")
    approval_url = "#{base_url}/approve/#{token}"

    message = "Hello #{@job_card.customer.name},\n\n" \
              "Your vehicle *#{@job_card.vehicle.registration_number}* service estimate is ready.\n\n" \
              "📋 Job Card: #{@job_card.job_card_number}\n" \
              "🔧 Service: #{@job_card.service_type&.name || 'General Service'}\n" \
              "💰 Estimate Total: ₹#{@estimate.grand_total}\n\n" \
              "Please review and approve your estimate here:\n#{approval_url}\n\n" \
              "Thank you,\n*Kuposu Bus Management*"

    begin
      whatsapp_service = WhatsappService.new
      whatsapp_service.send_and_log(
        recipient: @job_card.customer,
        message: message,
        user: @job_card.service_advisor
      )
    rescue => e
      Rails.logger.error "WhatsApp customer notification failed: #{e.message}"
    end

    @job_card.update(status: :estimate_sent) if @job_card.estimate_created?
  end

  # Send manager approval link via WhatsApp to the service advisor / manager
  def send_manager_approval_link
    manager = @job_card.service_advisor
    return unless manager&.phone.present?

    token = @job_card.manager_approval_token
    base_url = ENV.fetch("APP_BASE_URL", "http://localhost:3009")
    approval_url = "#{base_url}/manager-approve/#{token}"

    message = "Hello #{manager.name},\n\n" \
              "A customer has approved the estimate and it requires your approval.\n\n" \
              "📋 Job Card: #{@job_card.job_card_number}\n" \
              "🚗 Vehicle: #{@job_card.vehicle.registration_number}\n" \
              "👤 Customer: #{@job_card.customer.name}\n" \
              "💰 Estimate Total: ₹#{@estimate.grand_total}\n\n" \
              "Please review and approve here:\n#{approval_url}\n\n" \
              "- *Kuposu Bus Management*"

    begin
      whatsapp_service = WhatsappService.new
      whatsapp_service.send_and_log(
        recipient: manager,
        message: message,
        user: manager
      )
    rescue => e
      Rails.logger.error "WhatsApp manager notification failed: #{e.message}"
    end
  end
end
