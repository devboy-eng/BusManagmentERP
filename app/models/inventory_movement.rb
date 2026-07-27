class InventoryMovement < ApplicationRecord
  belongs_to :spare_part
  belongs_to :warehouse
  belongs_to :performed_by, class_name: "User"

  enum movement_type: { purchase_in: 0, repair_out: 1, return_in: 2, adjustment: 3, transfer: 4, damage: 5 }

  validates :quantity, presence: true
end
