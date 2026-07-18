class WhatsappMarketingController < ApplicationController
  def index
    @leads = Lead.all
    @customers = Customer.active
    @total_leads = Lead.count
    @total_customers = Customer.active.count
    @configured = WhatsappSetting.configured?
    @recent_messages = WhatsappMessage.recent.limit(5)
    @upcoming_follow_ups = FollowUp.upcoming.includes(:lead).limit(5)
  end

  def compose
    @recipients = if params[:type] == "customers"
      Customer.active.whatsapp_opted_in
    else
      Lead.whatsapp_opted_in
    end
    @type = params[:type] || "leads"
    @templates = WhatsappTemplate.ordered
  end

  def send_message
    @recipient_ids = params[:recipient_ids] || []
    @message = params[:message]
    @type = params[:type]

    if @recipient_ids.empty? || @message.blank?
      redirect_to compose_whatsapp_marketing_index_path(type: @type), alert: "Please select recipients and enter a message."
      return
    end

    unless WhatsappSetting.configured?
      redirect_to compose_whatsapp_marketing_index_path(type: @type), alert: "WhatsApp API is not configured. Please update settings first."
      return
    end

    model = @type == "customers" ? Customer : Lead
    count = 0

    @recipient_ids.each do |id|
      recipient = model.find_by(id: id)
      next if recipient.nil? || recipient.whatsapp_opt_out?

      SendWhatsappMessageJob.perform_later(
        recipient_type: model.name,
        recipient_id: recipient.id,
        message: @message,
        user_id: current_user.id
      )
      count += 1
    end

    redirect_to whatsapp_marketing_index_path, notice: "WhatsApp message queued for #{count} recipient(s)."
  end

  def send_bulk
    @type = params[:type] || "leads"
    @message = params[:message]

    if @message.blank?
      redirect_to compose_whatsapp_marketing_index_path(type: @type), alert: "Please enter a message."
      return
    end

    unless WhatsappSetting.configured?
      redirect_to compose_whatsapp_marketing_index_path(type: @type), alert: "WhatsApp API is not configured. Please update settings first."
      return
    end

    recipients = @type == "customers" ? Customer.active.whatsapp_opted_in : Lead.whatsapp_opted_in
    model_name = @type == "customers" ? "Customer" : "Lead"
    count = 0

    recipients.find_each do |recipient|
      SendWhatsappMessageJob.perform_later(
        recipient_type: model_name,
        recipient_id: recipient.id,
        message: @message,
        user_id: current_user.id
      )
      count += 1
    end

    redirect_to whatsapp_marketing_index_path, notice: "Bulk WhatsApp message queued for #{count} recipient(s)."
  end

  def send_template
    template = WhatsappTemplate.find(params[:template_id])
    recipient_ids = params[:recipient_ids] || []
    type = params[:type]
    variables = (params[:variables] || []).map(&:to_s)

    if recipient_ids.empty?
      redirect_to compose_whatsapp_marketing_index_path(type: type), alert: "Please select at least one recipient."
      return
    end

    unless template.status == "approved"
      redirect_to compose_whatsapp_marketing_index_path(type: type), alert: "Template must be approved by Meta before sending."
      return
    end

    unless WhatsappSetting.configured?
      redirect_to compose_whatsapp_marketing_index_path(type: type), alert: "WhatsApp API is not configured."
      return
    end

    model = type == "customers" ? Customer : Lead
    service = WhatsappService.new
    sent = 0
    failed = 0
    last_error = nil

    recipient_ids.each do |id|
      recipient = model.find(id)
      next if recipient.whatsapp_opt_out?

      result = service.send_template_and_log(
        recipient: recipient,
        template: template,
        variables: variables,
        user: current_user
      )
      if result[:result][:success]
        sent += 1
      else
        failed += 1
        last_error = result[:result][:error]
      end
    end

    if failed > 0
      redirect_to whatsapp_marketing_index_path, alert: "Template send failed for #{failed} recipient(s): #{last_error}"
    else
      redirect_to whatsapp_marketing_index_path, notice: "Template '#{template.name}' sent to #{sent} recipient(s)."
    end
  rescue => e
    redirect_to compose_whatsapp_marketing_index_path(type: type), alert: "Error: #{e.message}"
  end

  def send_quick
    recipient_type = params[:recipient_type]
    recipient_id = params[:recipient_id]
    message = params[:message]

    if message.blank?
      redirect_back fallback_location: root_path, alert: "Message cannot be blank."
      return
    end

    unless WhatsappSetting.configured?
      redirect_back fallback_location: root_path, alert: "WhatsApp API is not configured."
      return
    end

    SendWhatsappMessageJob.perform_later(
      recipient_type: recipient_type,
      recipient_id: recipient_id.to_i,
      message: message,
      user_id: current_user.id
    )

    redirect_back fallback_location: root_path, notice: "WhatsApp message queued for sending."
  end

  def message_log
    @messages = WhatsappMessage.recent

    if params[:search].present?
      @messages = @messages.where("recipient_name LIKE ? OR recipient_phone LIKE ? OR message_body LIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    if params[:status].present?
      @messages = @messages.where(status: params[:status])
    end

    @pagy, @messages = pagy(@messages, items: 20)
  end
end
