class AddEditionTypeAndPriceAndCityToEditions < ActiveRecord::Migration[8.1]
  def change
    add_column :editions, :edition_type, :string
    add_column :editions, :price, :string
    add_column :editions, :city, :string
  end
end
