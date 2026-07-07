class WhatsappTemplatesController < ApplicationController
  before_action :set_template, only: [:edit, :update, :destroy, :sync_to_meta, :sync_status, :delete_from_meta]

  def index
    @templates = WhatsappTemplate.ordered
  end

  def new
    @template = WhatsappTemplate.new(language: "en", header_type: "none")
  end

  def create
    @template = current_user.whatsapp_templates.build(template_params)
    if @template.save
      redirect_to whatsapp_templates_path, notice: "Template created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to whatsapp_templates_path, notice: "Template updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @template.meta_template_id.present?
      begin
        WhatsappService.new.delete_template(@template)
      rescue => e
        Rails.logger.warn("Failed to delete template from Meta: #{e.message}")
      end
    end
    @template.destroy
    redirect_to whatsapp_templates_path, notice: "Template deleted successfully."
  end

  def sync_to_meta
    unless WhatsappSetting.configured?
      redirect_to whatsapp_templates_path, alert: "Please configure WhatsApp settings first."
      return
    end

    result = WhatsappService.new.create_template(@template)
    if result[:success]
      redirect_to whatsapp_templates_path, notice: "Template submitted to Meta. Status: Pending review."
    else
      redirect_to whatsapp_templates_path, alert: "Failed to sync: #{result[:error]}"
    end
  rescue => e
    redirect_to whatsapp_templates_path, alert: "Error: #{e.message}"
  end

  def sync_status
    unless @template.meta_template_id.present?
      redirect_to whatsapp_templates_path, alert: "Template not synced to Meta yet."
      return
    end

    result = WhatsappService.new.sync_status_from_meta(@template)
    if result[:success]
      redirect_to whatsapp_templates_path, notice: "Status updated: #{result[:status]&.titleize}"
    else
      redirect_to whatsapp_templates_path, alert: "Failed to sync status: #{result[:error]}"
    end
  rescue => e
    redirect_to whatsapp_templates_path, alert: "Error: #{e.message}"
  end

  def delete_from_meta
    unless @template.meta_template_id.present?
      redirect_to whatsapp_templates_path, alert: "Template not synced to Meta."
      return
    end

    result = WhatsappService.new.delete_template(@template)
    if result[:success]
      redirect_to whatsapp_templates_path, notice: "Template removed from Meta."
    else
      redirect_to whatsapp_templates_path, alert: "Failed to delete from Meta: #{result[:error]}"
    end
  rescue => e
    redirect_to whatsapp_templates_path, alert: "Error: #{e.message}"
  end

  private

  def set_template
    @template = WhatsappTemplate.find(params[:id])
  end

  def template_params
    params.require(:whatsapp_template).permit(:name, :body, :category, :language, :header_type, :header_text, :header_media_url, :footer)
  end
end
