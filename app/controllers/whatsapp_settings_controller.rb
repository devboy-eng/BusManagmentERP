class WhatsappSettingsController < ApplicationController
  before_action :require_super_admin!, only: [:update]

  def edit
    @setting = WhatsappSetting.instance
    load_phone_numbers if current_user.super_admin?
  end

  def update
    @setting = WhatsappSetting.instance
    if @setting.update(setting_params)
      load_phone_numbers
      if @phone_numbers&.any?
        redirect_to edit_whatsapp_setting_path, notice: "Settings saved. Please select your phone number below."
      else
        redirect_to edit_whatsapp_setting_path, notice: "WhatsApp settings saved successfully."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def test_connection
    @setting = WhatsappSetting.instance

    unless WhatsappSetting.configured?
      redirect_to edit_whatsapp_setting_path, alert: "Please configure and activate WhatsApp settings first."
      return
    end

    begin
      service = WhatsappService.new
      result = service.test_connection

      if result[:success]
        redirect_to edit_whatsapp_setting_path, notice: "Connection successful! Phone: #{result[:phone_number]}"
      else
        redirect_to edit_whatsapp_setting_path, alert: "Connection failed: #{result[:error]}"
      end
    rescue => e
      redirect_to edit_whatsapp_setting_path, alert: "Connection error: #{e.message}"
    end
  end

  def sync_quality
    @setting = WhatsappSetting.instance

    unless WhatsappSetting.configured?
      redirect_to edit_whatsapp_setting_path, alert: "Please configure and activate WhatsApp settings first."
      return
    end

    SyncWhatsappQualityJob.perform_now
    @setting.reload
    redirect_to edit_whatsapp_setting_path, notice: "Quality score synced: #{@setting.quality_rating || 'N/A'}"
  rescue => e
    redirect_to edit_whatsapp_setting_path, alert: "Quality sync failed: #{e.message}"
  end

  private

  def load_phone_numbers
    return unless @setting.access_token.present? && @setting.business_account_id.present?

    result = WhatsappService.fetch_phone_numbers(
      access_token: @setting.access_token,
      business_account_id: @setting.business_account_id
    )
    @phone_numbers = result[:phone_numbers] if result[:success]
  rescue => e
    Rails.logger.warn("Failed to fetch phone numbers: #{e.message}")
  end

  def setting_params
    params.require(:whatsapp_setting).permit(:phone_number_id, :access_token, :business_account_id, :active, :webhook_url, :verify_token, :app_secret, :app_id)
  end
end
