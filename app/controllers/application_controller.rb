class ApplicationController < ActionController::Base
  protect_from_forgery

  def distance_of_time_until_today(time)
    return ActionView::Base.new.distance_of_time_in_words(time, Time.now)
  end

  def after_sign_in_path_for(resource)
    puts "after_sign_in_path_for"
    if request.session[:return_to].is_a? String
      [request.session[:return_to], request.session[:return_params].to_query].join("?")
    elsif request.session[:return_to].is_a? Hash
      request.session[:return_to].merge!(request.session[:return_params])
    else
      super
    end
  end

end
