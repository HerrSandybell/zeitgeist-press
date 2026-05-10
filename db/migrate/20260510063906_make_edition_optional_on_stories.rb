class MakeEditionOptionalOnStories < ActiveRecord::Migration[8.1]
  def change
    change_column_null :stories, :edition_id, true
  end
end
