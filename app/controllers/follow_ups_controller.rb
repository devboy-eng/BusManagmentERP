class FollowUpsController < ApplicationController
  def index
    @campaigns = FollowUpCampaign.includes(:whatsapp_template, :user).ordered

    if params[:status].present?
      @campaigns = @campaigns.where(status: params[:status])
    end

    @pagy, @campaigns = pagy(@campaigns, items: 15)
  end

  def new
    @leads = Lead.whatsapp_opted_in.order(:name)
    @customers = Customer.active.whatsapp_opted_in.order(:name)
    @templates = WhatsappTemplate.approved.ordered
  end

  def create
    template = WhatsappTemplate.find_by(id: params[:template_id])
    unless template
      @leads = Lead.whatsapp_opted_in.order(:name)
      @customers = Customer.active.whatsapp_opted_in.order(:name)
      @templates = WhatsappTemplate.approved.ordered
      flash.now[:alert] = "Please select an approved template."
      render :new, status: :unprocessable_entity
      return
    end

    campaign = FollowUpCampaign.new(
      name: params[:campaign_name].presence,
      whatsapp_template: template,
      template_variables: (params[:variables].presence || []).to_json,
      scheduled_at: params[:scheduled_at],
      user: current_user
    )

    # Collect contacts from selected leads
    contacts_data = []
    if params[:lead_ids].present?
      Lead.where(id: params[:lead_ids], whatsapp_opt_out: false).each do |lead|
        contacts_data << { lead: lead, name: lead.name, phone: lead.phone }
      end
    end

    # Collect contacts from selected customers
    if params[:customer_ids].present?
      Customer.where(id: params[:customer_ids], whatsapp_opt_out: false).each do |customer|
        contacts_data << { customer: customer, name: customer.name, phone: customer.phone }
      end
    end

    # Collect contacts from CSV upload
    if params[:csv_contacts].present?
      params[:csv_contacts].each do |csv_contact|
        next if csv_contact[:phone].blank?
        contacts_data << { lead: nil, name: csv_contact[:name], phone: csv_contact[:phone] }
      end
    end

    # Deduplicate by normalized phone (preserves lead > customer > CSV priority)
    seen_phones = Set.new
    contacts_data = contacts_data.select do |cd|
      normalized = WhatsappService.normalize_phone(cd[:phone])
      seen_phones.add?(normalized) ? true : false
    end

    if contacts_data.empty?
      @leads = Lead.whatsapp_opted_in.order(:name)
      @customers = Customer.active.whatsapp_opted_in.order(:name)
      @templates = WhatsappTemplate.approved.ordered
      flash.now[:alert] = "Please select at least one recipient."
      render :new, status: :unprocessable_entity
      return
    end

    if campaign.save
      contacts_data.each do |cd|
        campaign.contacts.create!(
          lead: cd[:lead],
          customer: cd[:customer],
          name: cd[:name],
          phone: cd[:phone]
        )
      end
      campaign.update!(total_contacts: contacts_data.size)

      redirect_to follow_ups_path, notice: "Campaign scheduled with #{contacts_data.size} recipients."
    else
      @leads = Lead.whatsapp_opted_in.order(:name)
      @customers = Customer.active.whatsapp_opted_in.order(:name)
      @templates = WhatsappTemplate.approved.ordered
      flash.now[:alert] = campaign.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  # Legacy follow-up actions
  def cancel
    @follow_up = FollowUp.find_by(id: params[:id])
    if @follow_up
      if @follow_up.pending?
        @follow_up.update!(status: :cancelled)
        redirect_to follow_ups_path, notice: "Follow-up cancelled."
      else
        redirect_to follow_ups_path, alert: "Only pending follow-ups can be cancelled."
      end
    else
      redirect_to follow_ups_path, alert: "Follow-up not found."
    end
  end

  def destroy
    @follow_up = FollowUp.find_by(id: params[:id])
    if @follow_up
      @follow_up.destroy
      redirect_to follow_ups_path, notice: "Follow-up deleted."
    else
      redirect_to follow_ups_path, alert: "Follow-up not found."
    end
  end
end
