class AddPublishedToEditions < ActiveRecord::Migration[8.1]
  def change
    add_column :editions, :published, :boolean, default: false, null: false
  end
end
