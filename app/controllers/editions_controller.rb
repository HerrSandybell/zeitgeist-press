class EditionsController < ApplicationController
  def show
    @edition = Edition.includes(:newspaper).find(params[:id])
    @stories = @edition.stories.order(:story_type)
  end
end