class HomeController < ApplicationController

  def index
    @popular_stations = Radio.limit(5)
    @popular_countries = ["Spain", "Japan", "China", "Italy", "Canada"]
    @ads = Radio.limit(5)

    respond_to do |format|
      format.html # { render :action => "home" }
    end

  end

end
