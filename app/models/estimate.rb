class Estimate < ApplicationRecord
  belongs_to :job_card
  belongs_to :created_by, class_name: "User"
  has_many :line_items, class_name: "EstimateLineItem", dependent: :destroy

  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  enum status: { draft: 0, sent: 1, approved: 2, rejected: 3, revised: 4 }

  validates :estimate_number, presence: true, uniqueness: true

  before_validation :generate_estimate_number, on: :create
  before_save :calculate_totals

  private

  def generate_estimate_number
    return if estimate_number.present?
    year = Date.current.year
    last = Estimate.where("estimate_number LIKE ?", "EST-#{year}-%").order(:estimate_number).last
    next_num = last ? last.estimate_number.split("-").last.to_i + 1 : 1
    self.estimate_number = "EST-#{year}-#{next_num.to_s.rjust(4, '0')}"
  end

  def calculate_totals
    self.labor_total = line_items.select { |li| li.item_type == "labor" }.sum(&:total_price)
    self.parts_total = line_items.select { |li| li.item_type == "part" }.sum(&:total_price)
    self.subtotal = labor_total + parts_total
    net = subtotal - (discount_amount || 0)
    if tax_type == "igst"
      self.igst_amount = (net * (igst_rate || 18) / 100).round(2)
      self.cgst_amount = 0
      self.sgst_amount = 0
    else
      self.cgst_amount = (net * (cgst_rate || 9) / 100).round(2)
      self.sgst_amount = (net * (sgst_rate || 9) / 100).round(2)
      self.igst_amount = 0
    end
    self.total_tax = cgst_amount + sgst_amount + igst_amount
    self.grand_total = net + total_tax
  end
end
