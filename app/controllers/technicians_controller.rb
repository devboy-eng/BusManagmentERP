class TechniciansController < ApplicationController
  before_action :set_technician, only: [:show, :edit, :update, :destroy]

  def index
    @technicians = Technician.includes(:branch).all
    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @technicians = @technicians.where("name LIKE ? OR employee_id LIKE ?", search, search)
    end
    @pagy, @technicians = pagy(@technicians, items: 15)
  end

  def show
    @assignments = @technician.technician_assignments.includes(job_card: :vehicle).order(created_at: :desc).limit(20)
  end

  def new
    @technician = Technician.new
    @branches = Branch.active
  end

  def create
    @technician = Technician.new(technician_params)
    if @technician.save
      redirect_to technician_path(@technician), notice: "Technician added."
    else
      @branches = Branch.active
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @branches = Branch.active
  end

  def update
    if @technician.update(technician_params)
      redirect_to technician_path(@technician), notice: "Technician updated."
    else
      @branches = Branch.active
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @technician.destroy
    redirect_to technicians_path, notice: "Technician deleted."
  end

  private

  def set_technician
    @technician = Technician.find(params[:id])
  end

  def technician_params
    params.require(:technician).permit(:name, :phone, :employee_id, :specialization,
      :hourly_rate, :status, :joined_on, :notes, :branch_id, :user_id)
  end
end
