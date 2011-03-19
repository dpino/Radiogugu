class FavoritesController < ApplicationController

  def index
    @favorites = Favorite.all
    session[:active_tab] = :favorites
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @favorites }
    end
  end

  def show

  end

  def new
    puts "new to favorites" + params[:id]
  end

  # GET /favorites/remove/:id
  # GET /favorites/remove/:id.json
  def remove
    return if current_user == nil

    # Remove favorite
    radio_id = params[:id]
    Favorite.delete_all(["radio_id = ? AND user_id = ?", radio_id, current_user.id])

    respond_to do |format|
      format.json { render :json => {:msg => "Removed from your list", :status => :OK }}
    end
  end

  # GET /favorites/add/:id
  # GET /favorites/add/:id.json
  def add
    return if current_user == nil

    # Check if radio already exists
    radio_id = params[:id]
    current_user_id = current_user.id
    radios = Favorite.where("radio_id = #{radio_id} AND user_id = #{current_user_id}")

    # Add radio if it doesn't exist
    if radios != nil && radios.size == 0
      @favorite = Favorite.new(:radio_id => radio_id, :user_id => current_user_id)
      @favorite.save
      result = {:notificationMsg => "Added to your list", :newMsg => "[Remove from your favorites]", :status => :OK }
    else
      result = {:notificationMsg => "Already in your list", :newMsg => "[Add to favorites]", :status => :ERROR }
    end

    respond_to do |format|
      format.json { render :json => result }
    end

  end

end
