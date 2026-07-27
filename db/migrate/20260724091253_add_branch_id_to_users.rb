class AddBranchIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :branch, foreign_key: true, null: true
  end
end
