class CreateInspections < ActiveRecord::Migration[7.1]
  def change
    create_table :inspections do |t|
      t.references :job_card, null: false, foreign_key: true
      t.references :inspected_by, null: false, foreign_key: { to_table: :users }
      t.text :general_notes
      t.integer :overall_condition, default: 0
      t.datetime :inspected_at
      t.timestamps
    end
  end
end
