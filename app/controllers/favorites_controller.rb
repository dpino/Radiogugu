class FavoritesController < ApplicationController
  def index
    @favorites = Favorite.all
    session[:active_tab] = :favorites
    respond_to do |format|
      format.html
      format.xml { render xml: @favorites }
    end
  end

  def show
  end

  def new
  end

  # GET /favorites/remove/:id
  def remove
    return if current_user.nil?

    radio_id = params[:id]
    Favorite.where(radio_id: radio_id, user_id: current_user.id).delete_all

    respond_to do |format|
      format.json { render json: { msg: "Removed from your list", status: :OK } }
    end
  end

  # GET /favorites/add/:id
  def add
    return if current_user.nil?

    radio_id = params[:id]
    current_user_id = current_user.id
    radios = Favorite.where(radio_id: radio_id, user_id: current_user_id)

    if radios.empty?
      @favorite = Favorite.new(radio_id: radio_id, user_id: current_user_id)
      @favorite.save
      result = { notificationMsg: "Added to your list", newMsg: "[Remove from your favorites]", status: :OK }
    else
      result = { notificationMsg: "Already in your list", newMsg: "[Add to favorites]", status: :ERROR }
    end

    respond_to do |format|
      format.json { render json: result }
    end
  end
end
