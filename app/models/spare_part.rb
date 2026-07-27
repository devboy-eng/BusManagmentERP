class SparePart < ApplicationRecord
  has_many :stock_entries, dependent: :destroy
  has_many :inventory_movements, dependent: :destroy
  has_many :estimate_line_items
  has_many :invoice_line_items
  has_many :purchase_order_items

  validates :part_number, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active_parts, -> { where(active: true) }
  scope :low_stock, -> { where("current_stock <= reorder_level") }
  scope :out_of_stock, -> { where(current_stock: 0) }
  scope :by_category, ->(cat) { where(category: cat) }

  CATEGORIES = ["Engine", "Brake", "Electrical", "Body", "AC", "Tyres", "Filters", "Fluids & Lubricants", "Suspension", "Transmission"].freeze

  def deduct_stock!(qty)
    update!(current_stock: [current_stock - qty, 0].max)
  end

  def add_stock!(qty)
    update!(current_stock: current_stock + qty)
  end
end
