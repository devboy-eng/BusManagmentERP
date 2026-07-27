class TechnicianAssignmentsController < ApplicationController
  before_action :set_job_card

  def create
    @assignment = @job_card.technician_assignments.build(assignment_params)
    if @assignment.save
      redirect_to job_card_path(@job_card), notice: "Technician assigned."
    else
      redirect_to job_card_path(@job_card), alert: "Could not assign technician."
    end
  end

  def update
    @assignment = @job_card.technician_assignments.find(params[:id])
    if @assignment.update(assignment_params)
      redirect_to job_card_path(@job_card), notice: "Assignment updated."
    else
      redirect_to job_card_path(@job_card), alert: "Could not update."
    end
  end

  def destroy
    @assignment = @job_card.technician_assignments.find(params[:id])
    @assignment.destroy
    redirect_to job_card_path(@job_card), notice: "Technician unassigned."
  end

  private

  def set_job_card
    @job_card = JobCard.find(params[:job_card_id])
  end

  def assignment_params
    params.require(:technician_assignment).permit(:technician_id, :task_description,
      :estimated_hours, :actual_hours, :status, :started_at, :completed_at, :notes)
  end
end
