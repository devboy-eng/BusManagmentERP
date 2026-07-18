class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @customers = Customer.all

    if params[:search].present?
      search = params[:search].strip
      if search.downcase == "active"
        @customers = @customers.active
      elsif search.downcase == "inactive"
        @customers = @customers.where(active: false)
      else
        @customers = @customers.where("name LIKE ? OR phone LIKE ? OR email LIKE ? OR pan LIKE ? OR gst LIKE ? OR trademark LIKE ?",
          "%#{search}%", "%#{search}%", "%#{search}%",
          "%#{search}%", "%#{search}%", "%#{search}%")
      end
    end

    if params[:sort].present?
      direction = params[:direction] == "desc" ? "desc" : "asc"
      @customers = @customers.order("#{params[:sort]} #{direction}")
    else
      @customers = @customers.order(created_at: :desc)
    end

    @pagy, @customers = pagy(@customers, items: 15)
  end

  def show
    @comments = @customer.comments.includes(:user)
    @comment = Comment.new
    @whatsapp_messages = @customer.whatsapp_messages.recent.limit(5)
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
    @customer.user = current_user
    if @customer.save
      redirect_to customers_path, notice: "Customer created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: "Customer updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: "Customer deleted successfully."
  end

  def toggle_status
    new_status = if params[:status].present?
      params[:status]
    else
      @customer.active? ? :non_active : :active
    end
    @customer.update(status: new_status)
    redirect_back fallback_location: customers_path, notice: "Customer status updated."
  end

  def bulk_upload
  end

  def import
    if params[:file].blank?
      redirect_to bulk_upload_customers_path, alert: "Please select a CSV file."
      return
    end

    require "csv"
    file = params[:file]
    count = 0

    CSV.foreach(file.path, headers: true, header_converters: :downcase) do |row|
      Customer.create(
        name: row["name"],
        phone: row["phone"],
        email: row["email"] || row["email id"],
        address: row["address"],
        pan: row["pan"],
        gst: row["gst"],
        trademark: row["trademark"],
        user: current_user
      )
      count += 1
    end

    redirect_to customers_path, notice: "#{count} customers imported successfully."
  rescue StandardError => e
    redirect_to bulk_upload_customers_path, alert: "Import failed: #{e.message}"
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :phone, :email, :address, :pan, :gst, :trademark, :status)
  end
end
