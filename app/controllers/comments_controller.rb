class CommentsController < ApplicationController
  # GET /comments
  def index
    @comments = Comment.order(updated_at: :desc)
    respond_to do |format|
      format.html
      format.xml { render xml: @comments }
    end
  end

  # GET /comments/1
  def show
    @comment = Comment.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render xml: @comment }
    end
  end

  # POST /radios/:radio_id/comments
  def create
    @radio = Radio.find(params[:radio_id])
    comment = @radio.comments.create(body: params[:comment], user_id: current_user.id)
    respond_to do |format|
      format.json { render json: to_comment_dto(comment), status: :ok }
    end
  end

  private

  def to_comment_dto(comment)
    {
      body: comment.body,
      username: comment.user.username,
      useremail: comment.user.email,
      time_distance: distance_of_time_until_today(DateTime.parse(comment.updated_at.to_s))
    }
  end
end
