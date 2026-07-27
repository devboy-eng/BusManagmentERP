class LowStockAlertJob < ApplicationJob
  queue_as :default

  def perform
    low_stock_parts = SparePart.low_stock
    Rails.logger.info "Low stock alert: #{low_stock_parts.count} parts below reorder level"
  end
end
