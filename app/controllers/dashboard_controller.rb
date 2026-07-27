class DashboardController < ApplicationController
  def index
    @vehicles_today = JobCard.where("checked_in_at >= ?", Date.current.beginning_of_day).count
    @active_job_cards = JobCard.active.count
    @awaiting_approval = JobCard.where(status: [:estimate_sent, :customer_approved]).count
    @in_workshop = JobCard.where(status: [:in_progress, :additional_work_requested]).count
    @completed_today = JobCard.where(status: [:completed, :gate_pass_issued]).where("work_completed_at >= ?", Date.current.beginning_of_day).count
    @revenue_this_month = Payment.where("paid_at >= ?", Date.current.beginning_of_month).sum(:amount)
    @pending_payments = Invoice.where(status: [:draft, :sent, :partially_paid]).sum(:grand_total) - Payment.joins(:invoice).where(invoices: { status: [:draft, :sent, :partially_paid] }).sum(:amount) rescue 0
    @low_stock_count = SparePart.low_stock.count
    @recent_job_cards = JobCard.includes(:vehicle, :customer, :service_advisor).order(created_at: :desc).limit(10)
    @recent_payments = Payment.includes(:customer, :invoice).order(paid_at: :desc).limit(5)
  end
end
