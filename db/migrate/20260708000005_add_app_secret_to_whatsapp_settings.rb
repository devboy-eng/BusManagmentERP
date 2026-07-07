class AddAppSecretToWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_settings, :app_secret, :string
  end
end
