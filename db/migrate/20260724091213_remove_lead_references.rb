class RemoveLeadReferences < ActiveRecord::Migration[7.1]
  def up
    # Clean polymorphic references
    execute "DELETE FROM comments WHERE commentable_type = 'Lead'"
    execute "UPDATE whatsapp_messages SET recipient_type = NULL, recipient_id = NULL WHERE recipient_type = 'Lead'"
    execute "UPDATE whatsapp_conversations SET contact_type = NULL, contact_id = NULL WHERE contact_type = 'Lead'"
    execute "UPDATE csat_responses SET respondent_type = NULL, respondent_id = NULL WHERE respondent_type = 'Lead'"
    execute "UPDATE follow_up_campaign_contacts SET lead_id = NULL WHERE lead_id IS NOT NULL"

    remove_column :follow_up_campaign_contacts, :lead_id if column_exists?(:follow_up_campaign_contacts, :lead_id)
  end

  def down
    add_reference :follow_up_campaign_contacts, :lead, foreign_key: true, null: true
  end
end
