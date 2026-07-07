class AddCategoryToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :category, :string
  end
end
