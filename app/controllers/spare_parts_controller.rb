class SparePartsController < ApplicationController
  before_action :set_spare_part, only: [:show, :edit, :update, :destroy]

  def index
    @spare_parts = SparePart.all
    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @spare_parts = @spare_parts.where("name LIKE ? OR part_number LIKE ? OR category LIKE ?", search, search, search)
    end
    if params[:category].present?
      @spare_parts = @spare_parts.where(category: params[:category])
    end
    @spare_parts = @spare_parts.order(:name)
    @pagy, @spare_parts = pagy(@spare_parts, items: 15)
  end

  def low_stock
    @spare_parts = SparePart.low_stock.order(:current_stock)
    @pagy, @spare_parts = pagy(@spare_parts, items: 15)
    render :index
  end

  def show; end

  def new
    @spare_part = SparePart.new
  end

  def create
    @spare_part = SparePart.new(spare_part_params)
    if @spare_part.save
      redirect_to spare_part_path(@spare_part), notice: "Spare part added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @spare_part.update(spare_part_params)
      redirect_to spare_part_path(@spare_part), notice: "Spare part updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @spare_part.destroy
    redirect_to spare_parts_path, notice: "Spare part deleted."
  end

  private

  def set_spare_part
    @spare_part = SparePart.find(params[:id])
  end

  def spare_part_params
    params.require(:spare_part).permit(:part_number, :name, :description, :category, :brand,
      :compatible_makes, :unit, :selling_price, :cost_price, :reorder_level, :current_stock,
      :hsn_code, :warranty_months, :active)
  end
end
