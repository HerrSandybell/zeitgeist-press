class EditionsController < ApplicationController
  def show
    @edition = Edition.includes(:newspaper).find(params[:id])
    non_ads = @edition.stories.where.not(story_type: :advertisement).order(:story_type, :position)
    ads     = @edition.stories.advertisement.order(:position).limit(4)
    @stories = non_ads + ads
  end
end