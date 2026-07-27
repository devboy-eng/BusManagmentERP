class Invoice < ApplicationRecord
  belongs_to :job_card
  belongs_to :customer
  belongs_to :branch
  belongs_to :created_by, class_name: "User"
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy
  has_many :payments, dependent: :destroy

  enum status: { draft: 0, sent: 1, partially_paid: 2, paid: 3, cancelled: 4 }

  validates :invoice_number, presence: true, uniqueness: true

  before_validation :generate_invoice_number, on: :create

  def balance_due
    grand_total - payments.sum(:amount)
  end

  private

  def generate_invoice_number
    return if invoice_number.present?
    year = Date.current.year
    last = Invoice.where("invoice_number LIKE ?", "INV-#{year}-%").order(:invoice_number).last
    next_num = last ? last.invoice_number.split("-").last.to_i + 1 : 1
    self.invoice_number = "INV-#{year}-#{next_num.to_s.rjust(4, '0')}"
  end
end
