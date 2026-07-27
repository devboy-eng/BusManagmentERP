class CreateJobCards < ActiveRecord::Migration[7.1]
  def change
    create_table :job_cards do |t|
      t.string :job_card_number, null: false
      t.references :vehicle, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.references :service_advisor, null: false, foreign_key: { to_table: :users }
      t.references :service_type, foreign_key: true, null: true
      t.integer :odometer_reading
      t.text :customer_complaints
      t.text :advisor_notes
      t.integer :status, default: 0, null: false
      t.integer :priority, default: 0
      t.datetime :checked_in_at
      t.datetime :estimated_completion_at
      t.datetime :work_started_at
      t.datetime :work_completed_at
      t.datetime :delivered_at
      t.string :customer_approval_token
      t.datetime :customer_approved_at
      t.text :customer_signature_data
      t.string :manager_approval_token
      t.datetime :manager_approved_at
      t.references :approved_by, foreign_key: { to_table: :users }, null: true
      t.string :gate_pass_number
      t.datetime :gate_pass_issued_at
      t.references :gate_pass_issued_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end
    add_index :job_cards, :job_card_number, unique: true
    add_index :job_cards, :status
    add_index :job_cards, :customer_approval_token, unique: true
    add_index :job_cards, :manager_approval_token, unique: true
  end
end
