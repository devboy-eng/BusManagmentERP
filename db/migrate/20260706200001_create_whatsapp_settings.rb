class CreateWhatsappSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_settings do |t|
      t.string :phone_number_id
      t.string :access_token
      t.string :business_account_id
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
