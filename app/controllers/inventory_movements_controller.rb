class InventoryMovementsController < ApplicationController
  def index
    @movements = InventoryMovement.includes(:spare_part, :warehouse, :performed_by).order(created_at: :desc)
    if params[:spare_part_id].present?
      @movements = @movements.where(spare_part_id: params[:spare_part_id])
    end
    if params[:movement_type].present?
      @movements = @movements.where(movement_type: params[:movement_type])
    end
    @pagy, @movements = pagy(@movements, items: 20)
  end
end
