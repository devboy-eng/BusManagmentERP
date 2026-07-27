class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update]

  def index
    @invoices = Invoice.includes(:job_card, :customer, :branch).order(created_at: :desc)
    if params[:status].present?
      @invoices = @invoices.where(status: params[:status])
    end
    if params[:search].present?
      search = "%#{params[:search].strip}%"
      @invoices = @invoices.joins(:customer).where("invoices.invoice_number LIKE ? OR customers.name LIKE ?", search, search)
    end
    @pagy, @invoices = pagy(@invoices, items: 15)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "invoice_#{@invoice.invoice_number}", template: "pdfs/invoice", layout: "pdf"
      end
    end
  end

  def edit; end

  def update
    if @invoice.update(invoice_params)
      redirect_to invoice_path(@invoice), notice: "Invoice updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:notes, :status)
  end
end
