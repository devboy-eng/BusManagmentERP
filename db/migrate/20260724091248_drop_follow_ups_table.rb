class DropFollowUpsTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :follow_ups if table_exists?(:follow_ups)
  end

  def down
    create_table :follow_ups do |t|
      t.references :lead, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :notes
      t.datetime :follow_up_date
      t.string :status
      t.timestamps
    end
  end
end
