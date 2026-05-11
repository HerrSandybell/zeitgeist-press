class StoriesController < ApplicationController
  def show_full
    @story = Story.find(params[:id])
    render :show_full, layout: false
  end
end
