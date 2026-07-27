class EstimateLineItem < ApplicationRecord
  belongs_to :estimate
  belongs_to :spare_part, optional: true
  belongs_to :technician, optional: true

  validates :description, presence: true
  validates :item_type, presence: true, inclusion: { in: %w[labor part] }

  before_save :calculate_total

  private

  def calculate_total
    self.total_price = (quantity || 0) * (unit_price || 0)
  end
end
