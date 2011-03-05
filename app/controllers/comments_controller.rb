class CommentsController < ApplicationController

  # GET /Comments
  # GET /Comments.xml
  def index
    @Comments = Comment.find(:all)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @Comments }
    end
  end

  # GET /Comments/1
  # GET /Comments/1.xml
  def show
    @Comment = Comment.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @Comment }
    end
  end

  # POST /comments
  # POST /comments.xml
  def create
    @radio = Radio.find(params[:radio_id])
    @comment = @radio.comments.create({:body => params[:comment], :user_id => current_user.id});
    respond_to do |format|
      format.json { render :json => @comment, :status => :ok }
    end
  end

end
