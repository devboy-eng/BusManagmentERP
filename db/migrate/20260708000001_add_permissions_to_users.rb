class AddPermissionsToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :permissions, :text

    # Set default permissions (all enabled) for existing users
    User.reset_column_information
    User.find_each do |user|
      user.update_column(:permissions, {
        dashboard: true,
        customers: true,
        leads: true,
        users: true,
        roles: true,
        whatsapp: true
      }.to_json)
    end
  end

  def down
    remove_column :users, :permissions
  end
end
