class CreateEditions < ActiveRecord::Migration[8.1]
  def change
    create_table :editions do |t|
      t.references :newspaper, null: false, foreign_key: true
      t.integer :year
      t.integer :season
      t.integer :day
      t.integer :volume
      t.integer :issue_number
      t.string :attention_bar

      t.timestamps
    end
  end
end
