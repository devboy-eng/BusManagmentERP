class AddQualityFieldsToWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_settings, :quality_rating, :string
    add_column :whatsapp_settings, :messaging_limit, :string
    add_column :whatsapp_settings, :quality_updated_at, :datetime
  end
end
