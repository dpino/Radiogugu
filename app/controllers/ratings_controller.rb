class RatingsController < ApplicationController

	def rate
		@asset = Radio.find(params[:id])
		Rating.delete_all(["rateable_type = 'Radio' AND rateable_id = ?", @asset.id)
		@asset.add_rating Rating.new(:rating => params[:rating])

		render :update do |page|
			page.replace_html "star-ratings-block-#{rateable.id}", :partial => "rate", :locals => { :asset => rateable }
			page.visual_effect :highlight, "star-ratings-block-#{rateable.id}"
	end

end
