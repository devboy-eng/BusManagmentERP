class DropCsatResponses < ActiveRecord::Migration[7.1]
  def up
    drop_table :csat_responses if table_exists?(:csat_responses)
  end

  def down
    create_table :csat_responses do |t|
      t.string :respondent_type
      t.integer :respondent_id
      t.references :branch, foreign_key: true, null: true
      t.integer :rating
      t.text :feedback
      t.string :token
      t.datetime :responded_at
      t.timestamps
    end
    add_index :csat_responses, :token, unique: true
    add_index :csat_responses, [:respondent_type, :respondent_id]
  end
end
