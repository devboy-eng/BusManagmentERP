class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy, :service_history]

  def index
    @vehicles = Vehicle.includes(:customer).all
    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @vehicles = @vehicles.where("registration_number LIKE ? OR make LIKE ? OR model LIKE ?", search, search, search)
    end
    if params[:status].present?
      @vehicles = @vehicles.where(status: params[:status])
    end
    @vehicles = @vehicles.order(created_at: :desc)
    @pagy, @vehicles = pagy(@vehicles, items: 15)
  end

  def show
    @job_cards = @vehicle.job_cards.order(created_at: :desc).limit(10)
  end

  def new
    @vehicle = Vehicle.new
    @vehicle.customer_id = params[:customer_id] if params[:customer_id]
    @customers = Customer.active.order(:name)
  end

  def create
    @vehicle = Vehicle.new(vehicle_params)
    if @vehicle.save
      redirect_to vehicle_path(@vehicle), notice: "Vehicle added."
    else
      @customers = Customer.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @customers = Customer.active.order(:name)
  end

  def update
    if @vehicle.update(vehicle_params)
      redirect_to vehicle_path(@vehicle), notice: "Vehicle updated."
    else
      @customers = Customer.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @vehicle.destroy
    redirect_to vehicles_path, notice: "Vehicle deleted."
  end

  def service_history
    @job_cards = @vehicle.job_cards.includes(:service_type, :branch).order(created_at: :desc)
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:customer_id, :registration_number, :vin, :make, :model,
      :year_of_manufacture, :engine_number, :chassis_number, :fuel_type, :seating_capacity,
      :current_odometer, :color, :insurance_provider, :insurance_policy_number,
      :insurance_expiry_date, :fitness_certificate_expiry, :permit_expiry_date,
      :puc_expiry_date, :notes, :status)
  end
end
