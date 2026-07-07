class CreateWhatsappTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_templates do |t|
      t.string :name, null: false
      t.text :body, null: false
      t.string :category
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
