class AddOtpEnabledToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :otp_enabled, :boolean, default: false, null: false
  end
end
