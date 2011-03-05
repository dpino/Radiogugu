class HomeController < ApplicationController

  def index
    session[:active_tab] = :home
    @popular_stations = Radio.limit(5)
    @popular_countries = ["Spain", "Japan", "China", "Italy", "Canada"]
    @ads = Radio.limit(5)

    respond_to do |format|
      format.html # { render :action => "home" }
    end

  end

end
