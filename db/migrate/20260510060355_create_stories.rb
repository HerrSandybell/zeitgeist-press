class CreateStories < ActiveRecord::Migration[8.1]
  def change
    create_table :stories do |t|
      t.references :edition, null: false, foreign_key: true
      t.integer :story_type
      t.integer :position
      t.string :headline
      t.text :body
      t.string :supertitle
      t.string :subtitle
      t.string :author
      t.text :quote
      t.string :quote_origin
      t.string :summary_ticker

      t.timestamps
    end
  end
end
