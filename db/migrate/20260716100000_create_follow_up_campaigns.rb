class CreateFollowUpCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :follow_up_campaigns do |t|
      t.string   :name
      t.integer  :whatsapp_template_id, null: false
      t.text     :template_variables
      t.datetime :scheduled_at, null: false
      t.integer  :status, default: 0
      t.integer  :user_id
      t.integer  :total_contacts, default: 0
      t.integer  :sent_count, default: 0
      t.integer  :delivered_count, default: 0
      t.integer  :read_count, default: 0
      t.integer  :failed_count, default: 0
      t.integer  :expired_count, default: 0
      t.timestamps
    end

    create_table :follow_up_campaign_contacts do |t|
      t.integer  :follow_up_campaign_id, null: false
      t.integer  :lead_id
      t.string   :name
      t.string   :phone, null: false
      t.integer  :status, default: 0
      t.string   :whatsapp_message_id
      t.text     :error_message
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :read_at
      t.timestamps
    end

    add_index :follow_up_campaign_contacts, :follow_up_campaign_id
    add_index :follow_up_campaign_contacts, :lead_id
    add_index :follow_up_campaign_contacts, :status
  end
end
