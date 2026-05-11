class EditionsController < ApplicationController
  def show
    @edition = Edition.includes(:newspaper).find(params[:id])
    load_stories
  end

  def show_current
    @edition = Edition.includes(:newspaper).where(published: true).order(:id).first!
    load_stories
    render :show
  end

  private

  def load_stories
    non_ads  = @edition.stories.where.not(story_type: :advertisement).order(:story_type, :position)
    ads      = @edition.stories.advertisement.order(:position).limit(4)
    @stories = non_ads + ads
  end
end