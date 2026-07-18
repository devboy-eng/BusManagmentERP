class AddPhoneDetailsAndProfileToWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    # Phone number details
    add_column :whatsapp_settings, :phone_display_number, :string
    add_column :whatsapp_settings, :verified_name, :string
    add_column :whatsapp_settings, :name_status, :string
    add_column :whatsapp_settings, :phone_status, :string
    add_column :whatsapp_settings, :code_verification_status, :string
    add_column :whatsapp_settings, :platform_type, :string

    # Business profile
    add_column :whatsapp_settings, :business_about, :string
    add_column :whatsapp_settings, :business_description, :text
    add_column :whatsapp_settings, :business_address, :string
    add_column :whatsapp_settings, :business_email, :string
    add_column :whatsapp_settings, :business_websites, :text
    add_column :whatsapp_settings, :business_vertical, :string
    add_column :whatsapp_settings, :profile_picture_url, :text

    # Sync timestamp
    add_column :whatsapp_settings, :profile_synced_at, :datetime
  end
end
