class JobCardsController < ApplicationController
  before_action :set_job_card, only: [:show, :edit, :update, :destroy, :advance_status, :send_estimate, :generate_invoice, :issue_gate_pass]

  def index
    @job_cards = JobCard.includes(:vehicle, :customer, :branch, :service_advisor, :service_type).all
    if params[:status].present?
      @job_cards = @job_cards.where(status: params[:status])
    end
    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @job_cards = @job_cards.joins(:customer, :vehicle).where(
        "job_cards.job_card_number LIKE ? OR customers.name LIKE ? OR vehicles.registration_number LIKE ?", search, search, search
      )
    end
    @job_cards = @job_cards.order(created_at: :desc)
    @pagy, @job_cards = pagy(@job_cards, items: 15)
  end

  def show
    @inspection = @job_card.inspections.last
    @estimates = @job_card.estimates.order(created_at: :desc)
    @invoices = @job_card.invoices.order(created_at: :desc)
    @assignments = @job_card.technician_assignments.includes(:technician)
    @comments = @job_card.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
  end

  def new
    @job_card = JobCard.new(checked_in_at: Time.current)
    @customers = Customer.active.order(:name)
    @vehicles = Vehicle.active_vehicles.order(:registration_number)
    @branches = Branch.active
    @service_types = ServiceType.active.ordered
    @users = User.all
  end

  def create
    @job_card = JobCard.new(job_card_params)
    @job_card.service_advisor = current_user unless @job_card.service_advisor_id
    @job_card.branch = current_user.branch || Branch.first unless @job_card.branch_id
    if @job_card.save
      redirect_to job_card_path(@job_card), notice: "Job card created."
    else
      @customers = Customer.active.order(:name)
      @vehicles = Vehicle.active_vehicles.order(:registration_number)
      @branches = Branch.active
      @service_types = ServiceType.active.ordered
      @users = User.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @customers = Customer.active.order(:name)
    @vehicles = Vehicle.active_vehicles.order(:registration_number)
    @branches = Branch.active
    @service_types = ServiceType.active.ordered
    @users = User.all
  end

  def update
    if @job_card.update(job_card_params)
      redirect_to job_card_path(@job_card), notice: "Job card updated."
    else
      @customers = Customer.active.order(:name)
      @vehicles = Vehicle.active_vehicles.order(:registration_number)
      @branches = Branch.active
      @service_types = ServiceType.active.ordered
      @users = User.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @job_card.update(status: :cancelled)
    redirect_to job_cards_path, notice: "Job card cancelled."
  end

  def advance_status
    next_statuses = {
      "checked_in" => "inspection_done",
      "inspection_done" => "estimate_created",
      "customer_approved" => "manager_approved",
      "manager_approved" => "in_progress",
      "in_progress" => "completed",
      "completed" => "invoiced"
    }
    next_status = next_statuses[@job_card.status]
    if next_status
      @job_card.update(status: next_status)
      @job_card.update(work_started_at: Time.current) if next_status == "in_progress"
      @job_card.update(work_completed_at: Time.current) if next_status == "completed"
      redirect_to job_card_path(@job_card), notice: "Status updated to #{next_status.titleize}."
    else
      redirect_to job_card_path(@job_card), alert: "Cannot advance from current status."
    end
  end

  def send_estimate
    estimate = @job_card.estimates.last
    if estimate
      EstimateNotificationService.new(@job_card, estimate).send_approval_link
      redirect_to job_card_path(@job_card), notice: "Estimate sent to customer."
    else
      redirect_to job_card_path(@job_card), alert: "No estimate found."
    end
  end

  def generate_invoice
    service = InvoiceService.new(@job_card, current_user)
    invoice = service.create_from_estimates
    if invoice
      redirect_to job_card_path(@job_card), notice: "Invoice generated."
    else
      redirect_to job_card_path(@job_card), alert: "Could not generate invoice."
    end
  end

  def issue_gate_pass
    GatePassService.new(@job_card, current_user).issue!
    redirect_to job_card_path(@job_card), notice: "Gate pass issued."
  end

  private

  def set_job_card
    @job_card = JobCard.find(params[:id])
  end

  def job_card_params
    params.require(:job_card).permit(:vehicle_id, :customer_id, :branch_id, :service_advisor_id,
      :service_type_id, :odometer_reading, :customer_complaints, :advisor_notes,
      :priority, :checked_in_at, :estimated_completion_at)
  end
end
