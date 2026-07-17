class AddCustomerIdToFollowUpCampaignContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :follow_up_campaign_contacts, :customer_id, :integer
    add_index :follow_up_campaign_contacts, :customer_id
  end
end
