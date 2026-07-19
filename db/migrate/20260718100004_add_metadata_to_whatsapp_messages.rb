class AddMetadataToWhatsappMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_messages, :metadata, :text
  end
end
