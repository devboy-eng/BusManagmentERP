class GatePassService
  def initialize(job_card, current_user)
    @job_card = job_card
    @current_user = current_user
  end

  def issue!
    year = Date.current.year
    last = JobCard.where("gate_pass_number LIKE ?", "GP-#{year}-%").order(:gate_pass_number).last
    next_num = last ? last.gate_pass_number.split("-").last.to_i + 1 : 1
    gate_pass_number = "GP-#{year}-#{next_num.to_s.rjust(4, '0')}"

    @job_card.update!(
      status: :gate_pass_issued, gate_pass_number: gate_pass_number,
      gate_pass_issued_at: Time.current, gate_pass_issued_by: @current_user,
      delivered_at: Time.current
    )

    send_customer_notification(gate_pass_number)
  end

  private

  def send_customer_notification(gate_pass_number)
    return unless @job_card.customer&.phone.present?

    message = "Hello #{@job_card.customer.name},\n\n" \
              "Your vehicle *#{@job_card.vehicle.registration_number}* is ready for pickup! 🎉\n\n" \
              "📋 Job Card: #{@job_card.job_card_number}\n" \
              "🎫 Gate Pass: #{gate_pass_number}\n\n" \
              "Please visit the service center to collect your vehicle.\n\n" \
              "Thank you for choosing *Kuposu Bus Management*!"

    begin
      whatsapp_service = WhatsappService.new
      whatsapp_service.send_and_log(
        recipient: @job_card.customer,
        message: message,
        user: @current_user
      )
    rescue => e
      Rails.logger.error "WhatsApp gate pass notification failed: #{e.message}"
    end
  end
end
