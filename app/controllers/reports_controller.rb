class ReportsController < ApplicationController
  def show; end

  def revenue
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current
    @payments = Payment.where(paid_at: @start_date.beginning_of_day..@end_date.end_of_day)
    @total_revenue = @payments.sum(:amount)
    @daily_revenue = @payments.group("date(paid_at)").sum(:amount)
  end

  def technician_productivity
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current
    @technicians = Technician.active_technicians.includes(:technician_assignments)
  end

  def parts_usage
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current
    @movements = InventoryMovement.where(movement_type: :repair_out)
      .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
      .includes(:spare_part).group(:spare_part_id).sum(:quantity)
  end

  def vehicle_turnaround
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current
    @completed_jobs = JobCard.where(status: :gate_pass_issued)
      .where(delivered_at: @start_date.beginning_of_day..@end_date.end_of_day)
  end

  def inventory_valuation
    @spare_parts = SparePart.where(active: true).order(:category, :name)
    @total_value = @spare_parts.sum { |p| p.current_stock * p.cost_price }
  end
end
