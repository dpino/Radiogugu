class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  def distance_of_time_until_today(time)
    ActionController::Base.helpers.distance_of_time_in_words(time, Time.now)
  end

  def after_sign_in_path_for(resource)
    if request.session[:return_to].is_a? String
      [request.session[:return_to], request.session[:return_params].to_query].join("?")
    elsif request.session[:return_to].is_a? Hash
      request.session[:return_to].merge!(request.session[:return_params])
    else
      super
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end
end
