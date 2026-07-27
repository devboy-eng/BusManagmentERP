class PaymentsController < ApplicationController
  def index
    @payments = Payment.includes(:invoice, :customer, :received_by).order(paid_at: :desc)
    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @payments = @payments.joins(:customer).where("customers.name LIKE ?", search)
    end
    @pagy, @payments = pagy(@payments, items: 15)
  end

  def new
    @invoice = Invoice.find(params[:invoice_id])
    @payment = Payment.new(invoice: @invoice, customer: @invoice.customer, paid_at: Time.current, amount: @invoice.balance_due)
  end

  def create
    @payment = Payment.new(payment_params)
    @payment.received_by = current_user
    if @payment.save
      redirect_to invoice_path(@payment.invoice), notice: "Payment recorded."
    else
      @invoice = @payment.invoice
      render :new, status: :unprocessable_entity
    end
  end

  private

  def payment_params
    params.require(:payment).permit(:invoice_id, :customer_id, :amount, :payment_method,
      :transaction_reference, :notes, :paid_at)
  end
end
