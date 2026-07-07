class CreateFollowUps < ActiveRecord::Migration[7.1]
  def change
    create_table :follow_ups do |t|
      t.references :lead, null: false, foreign_key: true
      t.text :message, null: false
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0
      t.string :whatsapp_message_id
      t.text :error_message
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :follow_ups, :scheduled_at
    add_index :follow_ups, :status
  end
end
