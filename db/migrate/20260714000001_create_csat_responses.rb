class CreateCsatResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :csat_responses do |t|
      t.string :token, null: false
      t.string :respondent_type
      t.integer :respondent_id
      t.integer :user_id
      t.integer :service_rating
      t.integer :support_rating
      t.boolean :would_recommend
      t.text :improvement_suggestion
      t.text :additional_comments
      t.datetime :submitted_at

      t.timestamps
    end

    add_index :csat_responses, :token, unique: true
    add_index :csat_responses, [:respondent_type, :respondent_id]
    add_index :csat_responses, :user_id
    add_index :csat_responses, :submitted_at
  end
end
