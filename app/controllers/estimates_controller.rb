class EstimatesController < ApplicationController
  before_action :set_job_card
  before_action :set_estimate, only: [:show, :edit, :update]

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "estimate_#{@estimate.estimate_number}", template: "pdfs/estimate", layout: "pdf"
      end
    end
  end

  def new
    @estimate = @job_card.estimates.build(created_by: current_user, is_additional: params[:additional] == "true")
    @estimate.line_items.build
    @spare_parts = SparePart.active_parts.order(:name)
    @technicians = Technician.active_technicians
    detect_tax_type
  end

  def create
    @estimate = @job_card.estimates.build(estimate_params)
    @estimate.created_by = current_user
    detect_tax_type
    if @estimate.save
      @job_card.update(status: :estimate_created) if @job_card.inspection_done? || @job_card.checked_in?
      redirect_to job_card_path(@job_card), notice: "Estimate created."
    else
      @spare_parts = SparePart.active_parts.order(:name)
      @technicians = Technician.active_technicians
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @spare_parts = SparePart.active_parts.order(:name)
    @technicians = Technician.active_technicians
  end

  def update
    if @estimate.update(estimate_params)
      redirect_to job_card_path(@job_card), notice: "Estimate updated."
    else
      @spare_parts = SparePart.active_parts.order(:name)
      @technicians = Technician.active_technicians
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_job_card
    @job_card = JobCard.find(params[:job_card_id])
  end

  def set_estimate
    @estimate = @job_card.estimates.find(params[:id])
  end

  def detect_tax_type
    customer_state = @job_card.customer&.state
    branch_state = @job_card.branch&.state
    if customer_state.present? && branch_state.present? && customer_state != branch_state
      @estimate.tax_type = "igst"
    else
      @estimate.tax_type = "cgst_sgst"
    end
  end

  def estimate_params
    params.require(:estimate).permit(:notes, :discount_amount, :discount_reason, :tax_type,
      :cgst_rate, :sgst_rate, :igst_rate,
      line_items_attributes: [:id, :item_type, :description, :spare_part_id, :technician_id,
        :quantity, :unit, :unit_price, :sort_order, :_destroy])
  end
end
