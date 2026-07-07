class AddFieldsToWhatsappTemplates < ActiveRecord::Migration[7.1]
  def up
    add_column :whatsapp_templates, :status, :string, default: "draft"
    add_column :whatsapp_templates, :header_type, :string, default: "none"
    add_column :whatsapp_templates, :header_text, :string
    add_column :whatsapp_templates, :header_media_url, :string
    add_column :whatsapp_templates, :language, :string, default: "en"
    add_column :whatsapp_templates, :footer, :string
    add_column :whatsapp_templates, :meta_template_id, :string

    # Nullify old category values that don't match new Meta-aligned values
    execute <<-SQL
      UPDATE whatsapp_templates
      SET category = NULL
      WHERE category IS NOT NULL
        AND category NOT IN ('marketing', 'utility', 'authentication')
    SQL
  end

  def down
    remove_column :whatsapp_templates, :status
    remove_column :whatsapp_templates, :header_type
    remove_column :whatsapp_templates, :header_text
    remove_column :whatsapp_templates, :header_media_url
    remove_column :whatsapp_templates, :language
    remove_column :whatsapp_templates, :footer
    remove_column :whatsapp_templates, :meta_template_id
  end
end
