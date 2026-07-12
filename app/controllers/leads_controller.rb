class LeadsController < ApplicationController
  before_action :set_lead, only: [:show, :edit, :update, :destroy, :update_status]

  def index
    @leads = Lead.all
    @leads = @leads.where("name LIKE ? OR phone LIKE ? OR email LIKE ? OR pan LIKE ? OR gst LIKE ? OR trademark LIKE ? OR category LIKE ?",
      "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%",
      "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    if params[:sort].present?
      direction = params[:direction] == "desc" ? "desc" : "asc"
      @leads = @leads.order("#{params[:sort]} #{direction}")
    else
      @leads = @leads.order(created_at: :desc)
    end

    @pagy, @leads = pagy(@leads, items: 15)
  end

  def show
    @comments = @lead.comments.includes(:user)
    @comment = Comment.new
    @whatsapp_messages = @lead.whatsapp_messages.recent.limit(5)
    @follow_ups = @lead.follow_ups.ordered.limit(5)
  end

  def new
    @lead = Lead.new
  end

  def create
    @lead = Lead.new(lead_params)
    @lead.user = current_user
    if @lead.save
      redirect_to leads_path, notice: "Lead created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @lead.update(lead_params)
      redirect_to leads_path, notice: "Lead updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lead.destroy
    redirect_to leads_path, notice: "Lead deleted successfully."
  end

  def update_status
    old_status = @lead.status
    new_status = params[:status]

    if @lead.update(status: new_status)
      @lead.comments.create!(
        body: "Status changed from #{old_status.titleize} to #{new_status.titleize}",
        user: current_user
      )
      redirect_back fallback_location: leads_path, notice: "Lead status updated."
    else
      redirect_back fallback_location: leads_path, alert: "Failed to update status."
    end
  end

  def bulk_upload
  end

  def import
    if params[:file].blank?
      redirect_to bulk_upload_leads_path, alert: "Please select a CSV file."
      return
    end

    require "csv"
    file = params[:file]
    count = 0

    CSV.foreach(file.path, headers: true, header_converters: :downcase) do |row|
      Lead.create(
        name: row["name"],
        phone: row["phone"],
        email: row["email"] || row["email id"],
        address: row["address"],
        pan: row["pan"],
        gst: row["gst"],
        trademark: row["trademark"],
        category: row["category"],
        user: current_user
      )
      count += 1
    end

    redirect_to leads_path, notice: "#{count} leads imported successfully."
  rescue StandardError => e
    redirect_to bulk_upload_leads_path, alert: "Import failed: #{e.message}"
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(:name, :phone, :email, :address, :pan, :gst, :trademark, :status, :category)
  end
end
