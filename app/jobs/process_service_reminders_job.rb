class ProcessServiceRemindersJob < ApplicationJob
  queue_as :default

  def perform
    ServiceReminderService.new.send_due_reminders
  end
end
