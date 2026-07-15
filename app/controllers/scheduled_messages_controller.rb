class ScheduledMessagesController < ApplicationController
  def index
    @scheduled_messages = ScheduledMessage.includes(:whatsapp_conversation, :user)
                                          .order(scheduled_at: :desc)
  end

  def destroy
    scheduled = ScheduledMessage.find(params[:id])
    scheduled.destroy
    redirect_to scheduled_messages_path, notice: "Scheduled message deleted.", status: :see_other
  end

  def cancel
    scheduled = ScheduledMessage.find(params[:id])
    if scheduled.pending?
      scheduled.update!(status: :cancelled)
      redirect_to scheduled_messages_path, notice: "Scheduled message cancelled.", status: :see_other
    else
      redirect_to scheduled_messages_path, alert: "Only pending messages can be cancelled.", status: :see_other
    end
  end
end
