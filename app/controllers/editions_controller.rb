class EditionsController < ApplicationController
  def index
    @edition = @newspaper.editions.find(params[:id])
    @stories = @edition.stories
  end

  def show
    @edition = Edition.includes(:stories).find(params[:id])
    @stories = @edition.stories.order(:position)
  end
end