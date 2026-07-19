class AddMissingIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :auto_reply_rules, :user_id
    add_index :comments, :user_id
    add_index :comments, [:commentable_type, :commentable_id]
    add_index :customers, :user_id
    add_index :leads, :user_id
    add_index :scheduled_messages, :user_id
    add_index :users, :role_id
    add_index :follow_up_campaigns, :whatsapp_template_id
    add_index :follow_up_campaigns, :user_id
    add_index :whatsapp_conversations, [:contact_type, :contact_id], if_not_exists: true
  end
end
