class PurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order
  belongs_to :spare_part

  validates :ordered_quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_cost, presence: true

  before_save :calculate_total

  private

  def calculate_total
    self.total_cost = (ordered_quantity || 0) * (unit_cost || 0)
  end
end
