class DashboardController < ApplicationController
  skip_before_action :authorize_feature!

  def index
    @total_customers = Rails.cache.fetch("dashboard/total_customers", expires_in: 10.minutes) { Customer.count }
    @active_customers = Rails.cache.fetch("dashboard/active_customers", expires_in: 10.minutes) { Customer.active.count }
    @total_leads = Rails.cache.fetch("dashboard/total_leads", expires_in: 10.minutes) { Lead.count }
    @pending_leads = Rails.cache.fetch("dashboard/pending_leads", expires_in: 10.minutes) { Lead.pending.count }
    @wip_leads = Rails.cache.fetch("dashboard/wip_leads", expires_in: 10.minutes) { Lead.work_in_process.count }
    @not_interested_leads = Rails.cache.fetch("dashboard/not_interested_leads", expires_in: 10.minutes) { Lead.not_interested.count }
    @recent_customers = Rails.cache.fetch("dashboard/recent_customers", expires_in: 5.minutes) { Customer.order(created_at: :desc).limit(5).to_a }
    @recent_leads = Rails.cache.fetch("dashboard/recent_leads", expires_in: 5.minutes) { Lead.order(created_at: :desc).limit(5).to_a }
  end
end
