class AddWhatsappOptOutToLeadsAndCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :whatsapp_opt_out, :boolean, default: false, null: false
    add_column :customers, :whatsapp_opt_out, :boolean, default: false, null: false
  end
end
