class AddButtonsToWhatsappTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_templates, :buttons, :text
  end
end
