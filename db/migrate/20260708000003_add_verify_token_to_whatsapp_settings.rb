class AddVerifyTokenToWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_settings, :verify_token, :string

    reversible do |dir|
      dir.up do
        WhatsappSetting.reset_column_information
        WhatsappSetting.find_each do |setting|
          setting.update_column(:verify_token, SecureRandom.hex(16))
        end
      end
    end
  end
end
