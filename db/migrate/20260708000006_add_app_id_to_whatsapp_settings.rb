class AddAppIdToWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_settings, :app_id, :string
  end
end
