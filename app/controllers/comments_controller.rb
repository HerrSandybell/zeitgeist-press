class CommentsController < ApplicationController
  before_action :set_edition

  def create
    @comment = @edition.comments.build(comment_params)
    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to newspaper_edition_path(@edition.newspaper, @edition) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("comment-errors",
            @comment.errors.full_messages.to_sentence),
            status: :unprocessable_entity
        end
        format.html { redirect_to newspaper_edition_path(@edition.newspaper, @edition) }
      end
    end
  end

  private

  def set_edition
    @edition = Edition.find(params[:edition_id])
  end

  def comment_params
    params.require(:comment).permit(:body, :character_id)
  end
end
