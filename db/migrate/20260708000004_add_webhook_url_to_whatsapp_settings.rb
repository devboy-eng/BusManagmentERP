class AddWebhookUrlToWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_settings, :webhook_url, :string
  end
end
