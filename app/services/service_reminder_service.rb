class ServiceReminderService
  def send_due_reminders
    ServiceReminder.where(status: :pending).where("due_date <= ?", Date.current + 3.days).find_each do |reminder|
      next unless reminder.customer&.phone.present?
      begin
        message = "Hello #{reminder.customer.name}, your vehicle #{reminder.vehicle.registration_number} " \
                  "#{reminder.reminder_type.titleize} is due on #{reminder.due_date.strftime('%d %b %Y')}. " \
                  "Please schedule your visit. - Bus Service Pro"
        WhatsappService.new.send_and_log(to: reminder.customer.phone, body: message, contact: reminder.customer)
        reminder.update(status: :sent, sent_at: Time.current)
      rescue => e
        Rails.logger.error "Reminder send failed: #{e.message}"
      end
    end
  end
end
