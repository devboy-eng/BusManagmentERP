class Branch < ApplicationRecord
  has_many :users
  has_many :customers
  has_many :job_cards
  has_many :invoices
  has_many :technicians
  has_many :warehouses
  has_many :purchase_orders

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :state, presence: true

  scope :active, -> { where(active: true) }
  scope :default, -> { find_by(is_default: true) }

  def self.default
    find_by(is_default: true) || first
  end
end
