class WarehousesController < ApplicationController
  before_action :set_warehouse, only: [:show, :edit, :update, :destroy]

  def index
    @warehouses = Warehouse.includes(:branch).all.order(:name)
    @pagy, @warehouses = pagy(@warehouses, items: 15)
  end

  def show
    @stock_entries = @warehouse.stock_entries.includes(:spare_part).order(created_at: :desc)
  end

  def new
    @warehouse = Warehouse.new
    @branches = Branch.active
  end

  def create
    @warehouse = Warehouse.new(warehouse_params)
    if @warehouse.save
      redirect_to warehouses_path, notice: "Warehouse created."
    else
      @branches = Branch.active
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @branches = Branch.active
  end

  def update
    if @warehouse.update(warehouse_params)
      redirect_to warehouses_path, notice: "Warehouse updated."
    else
      @branches = Branch.active
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @warehouse.destroy
    redirect_to warehouses_path, notice: "Warehouse deleted."
  end

  private

  def set_warehouse
    @warehouse = Warehouse.find(params[:id])
  end

  def warehouse_params
    params.require(:warehouse).permit(:name, :address, :contact_phone, :branch_id, :is_default, :active)
  end
end
