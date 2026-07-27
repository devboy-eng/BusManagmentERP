class InspectionsController < ApplicationController
  before_action :set_job_card

  def new
    @inspection = @job_card.inspections.build(inspected_by: current_user, inspected_at: Time.current)
    InspectionItem::AREAS.each { |area| @inspection.inspection_items.build(area: area) }
  end

  def create
    @inspection = @job_card.inspections.build(inspection_params)
    @inspection.inspected_by = current_user
    @inspection.inspected_at = Time.current
    if @inspection.save
      @job_card.update(status: :inspection_done) if @job_card.checked_in?
      redirect_to job_card_path(@job_card), notice: "Inspection completed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @inspection = @job_card.inspections.find(params[:id])
  end

  private

  def set_job_card
    @job_card = JobCard.find(params[:job_card_id])
  end

  def inspection_params
    params.require(:inspection).permit(:general_notes, :overall_condition,
      inspection_items_attributes: [:id, :area, :condition, :notes, :sort_order, :_destroy])
  end
end
