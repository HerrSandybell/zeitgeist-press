class EditionsController < ApplicationController
  def index
    @edition = @newspaper.editions.find(params[:id])
    @stories = @edition.stories
  end
end