class SuppliersController < ApplicationController
  before_action :set_supplier, only: [:show, :edit, :update, :destroy]

  def index
    @suppliers = Supplier.all
    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @suppliers = @suppliers.where("name LIKE ? OR contact_person LIKE ?", search, search)
    end
    @suppliers = @suppliers.order(:name)
    @pagy, @suppliers = pagy(@suppliers, items: 15)
  end

  def show
    @purchase_orders = @supplier.purchase_orders.order(created_at: :desc).limit(10)
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.new(supplier_params)
    if @supplier.save
      redirect_to supplier_path(@supplier), notice: "Supplier added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @supplier.update(supplier_params)
      redirect_to supplier_path(@supplier), notice: "Supplier updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier.destroy
    redirect_to suppliers_path, notice: "Supplier deleted."
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:name, :contact_person, :phone, :email, :address, :gst_number, :notes, :active)
  end
end
