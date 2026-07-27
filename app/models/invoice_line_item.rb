class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :spare_part, optional: true

  validates :description, presence: true
  validates :item_type, presence: true

  before_save :calculate_total

  private

  def calculate_total
    self.total_price = (quantity || 0) * (unit_price || 0)
  end
end
