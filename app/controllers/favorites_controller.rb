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
      result = {:msg => "Added to your list", :status => :OK }
    else
      result = {:msg => "Already in your list", :status => :ERROR }
    end


    respond_to do |format|
      format.json { render :json => result }
    end

  end

end
