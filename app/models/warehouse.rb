class Warehouse < ApplicationRecord
  belongs_to :branch, optional: true
  has_many :stock_entries, dependent: :destroy
  has_many :inventory_movements, dependent: :destroy
  has_many :purchase_orders

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  def self.default
    find_by(is_default: true) || first
  end
end
