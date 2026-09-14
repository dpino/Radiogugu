class RatingsController < ApplicationController
  # POST ratings/rate
  def rate
    rateable = Radio.find(params[:id])

    if user_signed_in?
      Rating.where(rateable_type: Radio.base_class.to_s, rateable_id: params[:id], user_id: current_user.id).delete_all
      rateable.add_rating Rating.new(rating: params[:rating], user_id: current_user.id)
    else
      rateable.add_rating Rating.new(rating: params[:rating])
    end

    respond_to do |format|
      format.json { render json: rateable.rating, status: :ok }
    end
  end
end
