class AddTaglineAndPrintLocationToNewspapers < ActiveRecord::Migration[8.1]
  def change
    add_column :newspapers, :tagline, :string
    add_column :newspapers, :print_location, :string
  end
end
