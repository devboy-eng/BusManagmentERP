class PurchaseOrdersController < ApplicationController
  before_action :set_purchase_order, only: [:show, :edit, :update, :destroy, :receive]

  def index
    @purchase_orders = PurchaseOrder.includes(:supplier, :warehouse, :branch).order(created_at: :desc)
    if params[:status].present?
      @purchase_orders = @purchase_orders.where(status: params[:status])
    end
    @pagy, @purchase_orders = pagy(@purchase_orders, items: 15)
  end

  def show; end

  def new
    @purchase_order = PurchaseOrder.new
    @purchase_order.items.build
    load_form_data
  end

  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    @purchase_order.created_by = current_user
    @purchase_order.branch = current_user.branch || Branch.first
    if @purchase_order.save
      redirect_to purchase_order_path(@purchase_order), notice: "Purchase order created."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @purchase_order.update(purchase_order_params)
      redirect_to purchase_order_path(@purchase_order), notice: "Purchase order updated."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def receive
    @purchase_order.items.each do |item|
      qty = params.dig(:received_quantities, item.id.to_s).to_i
      next if qty <= 0
      item.update!(received_quantity: item.received_quantity + qty)
      item.spare_part.add_stock!(qty)
      InventoryMovement.create!(
        spare_part: item.spare_part, warehouse: @purchase_order.warehouse,
        quantity: qty, movement_type: :purchase_in,
        reference_type: "PurchaseOrder", reference_id: @purchase_order.id,
        notes: "PO #{@purchase_order.po_number}", performed_by: current_user
      )
    end
    all_received = @purchase_order.items.all? { |i| i.received_quantity >= i.ordered_quantity }
    @purchase_order.update!(status: all_received ? :received : :partially_received, received_date: Date.current)
    redirect_to purchase_order_path(@purchase_order), notice: "Stock received."
  end

  def destroy
    @purchase_order.update(status: :cancelled)
    redirect_to purchase_orders_path, notice: "Purchase order cancelled."
  end

  private

  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  def load_form_data
    @suppliers = Supplier.active.order(:name)
    @warehouses = Warehouse.active.order(:name)
    @spare_parts = SparePart.active_parts.order(:name)
  end

  def purchase_order_params
    params.require(:purchase_order).permit(:supplier_id, :warehouse_id, :expected_delivery_date, :notes,
      items_attributes: [:id, :spare_part_id, :ordered_quantity, :unit_cost, :_destroy])
  end
end
