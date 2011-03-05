class RatingsController < ApplicationController

  # POST ratings/rate
    def rate
    rateable = Radio.find(params[:id])

    # Delete the old ratings for current user
    if user_signed_in?
      Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", Radio.base_class.to_s, params[:id], current_user.id])
      rateable.add_rating Rating.new(:rating => params[:rating], :user_id => current_user.id)
    else
      rateable.add_rating Rating.new(:rating => params[:rating])
    end

    respond_to do |format|
      format.json { render :json => rateable.rating, :status => :ok }
    end
    end

end
