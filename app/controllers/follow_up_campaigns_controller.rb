class FollowUpCampaignsController < ApplicationController
  def show
    @campaign = FollowUpCampaign.includes(:whatsapp_template, :contacts).find(params[:id])
    @analytics = @campaign.analytics
    @contacts = @campaign.contacts.order(:id)
  end

  def cancel
    @campaign = FollowUpCampaign.find(params[:id])
    if @campaign.pending?
      @campaign.update!(status: :cancelled)
      redirect_to follow_ups_path, notice: "Campaign cancelled."
    else
      redirect_to follow_ups_path, alert: "Only pending campaigns can be cancelled."
    end
  end

  def destroy
    @campaign = FollowUpCampaign.find(params[:id])
    @campaign.destroy
    redirect_to follow_ups_path, notice: "Campaign deleted."
  end
end
