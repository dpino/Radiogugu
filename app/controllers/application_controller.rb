class ApplicationController < ActionController::Base
  protect_from_forgery

  def distance_of_time_until_today(time)
    return ActionView::Base.new.distance_of_time_in_words(time, Time.now)
  end

end
