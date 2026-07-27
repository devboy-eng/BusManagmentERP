class CreateTechnicianAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :technician_assignments do |t|
      t.references :job_card, null: false, foreign_key: true
      t.references :technician, null: false, foreign_key: true
      t.string :task_description
      t.decimal :estimated_hours, precision: 6, scale: 2
      t.decimal :actual_hours, precision: 6, scale: 2
      t.integer :status, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.text :notes
      t.timestamps
    end
  end
end
