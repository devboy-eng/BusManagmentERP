class PurchaseOrder < ApplicationRecord
  belongs_to :supplier
  belongs_to :warehouse
  belongs_to :branch
  belongs_to :created_by, class_name: "User"
  has_many :items, class_name: "PurchaseOrderItem", dependent: :destroy

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank

  enum status: { draft: 0, sent: 1, partially_received: 2, received: 3, cancelled: 4 }

  validates :po_number, presence: true, uniqueness: true

  before_validation :generate_po_number, on: :create
  before_save :calculate_total

  private

  def generate_po_number
    return if po_number.present?
    year = Date.current.year
    last = PurchaseOrder.where("po_number LIKE ?", "PO-#{year}-%").order(:po_number).last
    next_num = last ? last.po_number.split("-").last.to_i + 1 : 1
    self.po_number = "PO-#{year}-#{next_num.to_s.rjust(4, '0')}"
  end

  def calculate_total
    self.total_amount = items.sum { |i| (i.ordered_quantity || 0) * (i.unit_cost || 0) }
  end
end
