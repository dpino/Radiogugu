class RatingsController < ApplicationController

	def rate

    rateable = Radio.find(params[:id])

    # Delete the old ratings for current user
    Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", Radio.base_class.to_s, params[:id], current_user.id])
    rateable.add_rating Rating.new(:rating => params[:rating], :user_id => current_user.id)

    respond_to do |format|
      format.json { render :json => rateable.rating, :status => :ok }
    end

	end

end
