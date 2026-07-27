class Supplier < ApplicationRecord
  has_many :purchase_orders, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
