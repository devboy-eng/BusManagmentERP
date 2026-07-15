class CreateWhatsappMenus < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_menus do |t|
      t.string  :name, null: false
      t.string  :header_text
      t.text    :body_text, null: false
      t.string  :footer_text
      t.string  :button_text, default: "Menu"
      t.text    :menu_items                       # JSON: [{id, title, description, reply_text}]
      t.string  :trigger_keyword                  # e.g. "menu", "help"
      t.boolean :active, default: true
      t.integer :user_id
      t.timestamps
    end

    add_index :whatsapp_menus, :trigger_keyword
    add_index :whatsapp_menus, :active
  end
end
