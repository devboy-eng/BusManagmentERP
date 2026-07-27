class Payment < ApplicationRecord
  belongs_to :invoice
  belongs_to :customer
  belongs_to :received_by, class_name: "User"

  enum payment_method: { cash: 0, upi: 1, card: 2, bank_transfer: 3, cheque: 4 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_at, presence: true

  after_create :update_invoice_status

  private

  def update_invoice_status
    total_paid = invoice.payments.sum(:amount)
    if total_paid >= invoice.grand_total
      invoice.update(status: :paid)
    elsif total_paid > 0
      invoice.update(status: :partially_paid)
    end
  end
end
