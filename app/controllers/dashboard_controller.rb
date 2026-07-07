class DashboardController < ApplicationController
  skip_before_action :authorize_feature!

  def index
    @total_customers = Customer.count
    @active_customers = Customer.active.count
    @total_leads = Lead.count
    @pending_leads = Lead.pending.count
    @wip_leads = Lead.work_in_process.count
    @not_interested_leads = Lead.not_interested.count
    @recent_customers = Customer.order(created_at: :desc).limit(5)
    @recent_leads = Lead.order(created_at: :desc).limit(5)
  end
end
