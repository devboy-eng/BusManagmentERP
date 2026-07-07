class FollowUpsController < ApplicationController
  def index
    @follow_ups = FollowUp.includes(:lead, :user).ordered

    if params[:status].present?
      @follow_ups = @follow_ups.where(status: params[:status])
    end

    @pagy, @follow_ups = pagy(@follow_ups, items: 15)
  end

  def new
    @follow_up = FollowUp.new
    @follow_up.lead_id = params[:lead_id] if params[:lead_id].present?
    @leads = Lead.order(:name)
  end

  def create
    @follow_up = current_user.follow_ups.build(follow_up_params)
    if @follow_up.save
      ProcessScheduledFollowUpsJob.set(wait_until: @follow_up.scheduled_at).perform_later
      redirect_to follow_ups_path, notice: "Follow-up scheduled successfully."
    else
      @leads = Lead.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @follow_up = FollowUp.find(params[:id])
    if @follow_up.pending?
      @follow_up.update!(status: :cancelled)
      redirect_to follow_ups_path, notice: "Follow-up cancelled."
    else
      redirect_to follow_ups_path, alert: "Only pending follow-ups can be cancelled."
    end
  end

  def destroy
    @follow_up = FollowUp.find(params[:id])
    @follow_up.destroy
    redirect_to follow_ups_path, notice: "Follow-up deleted."
  end

  private

  def follow_up_params
    params.require(:follow_up).permit(:lead_id, :message, :scheduled_at)
  end
end
