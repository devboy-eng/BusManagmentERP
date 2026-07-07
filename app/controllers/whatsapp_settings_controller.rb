class WhatsappSettingsController < ApplicationController
  def edit
    @setting = WhatsappSetting.instance
  end

  def update
    @setting = WhatsappSetting.instance
    if @setting.update(setting_params)
      redirect_to edit_whatsapp_setting_path, notice: "WhatsApp settings saved successfully."
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

  private

  def setting_params
    params.require(:whatsapp_setting).permit(:phone_number_id, :access_token, :business_account_id, :active, :webhook_url, :verify_token)
  end
end
