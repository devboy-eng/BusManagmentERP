class WhatsappEnhancements < ActiveRecord::Migration[7.1]
  def change
    # whatsapp_messages — add media + reaction columns
    add_column :whatsapp_messages, :message_type, :string, default: "text"
    add_column :whatsapp_messages, :media_url, :string
    add_column :whatsapp_messages, :media_mime_type, :string
    add_column :whatsapp_messages, :media_filename, :string
    add_column :whatsapp_messages, :media_caption, :string
    add_column :whatsapp_messages, :reaction_emoji, :string
    add_column :whatsapp_messages, :context_message_id, :string

    # whatsapp_conversations — add assignment
    add_column :whatsapp_conversations, :assigned_user_id, :integer
    add_index  :whatsapp_conversations, :assigned_user_id

    # whatsapp_messages — search index
    add_index :whatsapp_messages, :message_type

    # quick_responses table
    create_table :quick_responses do |t|
      t.string  :title, null: false
      t.text    :body, null: false
      t.string  :shortcode
      t.integer :user_id
      t.integer :usage_count, default: 0
      t.timestamps
    end
    add_index :quick_responses, :shortcode
    add_index :quick_responses, :user_id

    # auto_reply_rules table
    create_table :auto_reply_rules do |t|
      t.string  :name, null: false
      t.string  :trigger_type, default: "keyword"
      t.string  :keyword
      t.text    :reply_body, null: false
      t.boolean :active, default: true
      t.integer :user_id
      t.timestamps
    end
    add_index :auto_reply_rules, :active

    # scheduled_messages table
    create_table :scheduled_messages do |t|
      t.integer  :whatsapp_conversation_id, null: false
      t.text     :message_body, null: false
      t.datetime :scheduled_at, null: false
      t.integer  :status, default: 0
      t.string   :whatsapp_message_id
      t.text     :error_message
      t.integer  :user_id
      t.timestamps
    end
    add_index :scheduled_messages, :scheduled_at
    add_index :scheduled_messages, [:status, :scheduled_at]
    add_index :scheduled_messages, :whatsapp_conversation_id
  end
end
