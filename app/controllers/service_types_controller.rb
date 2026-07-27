class ServiceTypesController < ApplicationController
  before_action :set_service_type, only: [:edit, :update, :destroy]

  def index
    @service_types = ServiceType.ordered
    @pagy, @service_types = pagy(@service_types, items: 15)
  end

  def new
    @service_type = ServiceType.new
  end

  def create
    @service_type = ServiceType.new(service_type_params)
    if @service_type.save
      redirect_to service_types_path, notice: "Service type created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @service_type.update(service_type_params)
      redirect_to service_types_path, notice: "Service type updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service_type.destroy
    redirect_to service_types_path, notice: "Service type deleted."
  end

  private

  def set_service_type
    @service_type = ServiceType.find(params[:id])
  end

  def service_type_params
    params.require(:service_type).permit(:name, :description, :base_labor_charge, :estimated_hours, :active, :sort_order)
  end
end
