class AddTemplateTypeAndCarouselToWhatsappTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_templates, :template_type, :string, default: "standard"
    add_column :whatsapp_templates, :carousel_cards, :text
  end
end
