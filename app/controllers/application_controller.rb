class ApplicationController < ActionController::Base
  helper_method :current_user

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  def default_url_options
    if Rails.env.production?
      {:host => ENV['hostname']}
    else
      super
    end
  end

  def login!(user)
    @current_user = user
    session[:session_token] = user.session_token
  end

  def logout!
    current_user&.reset_session_token!
    session[:session_token] = nil
  end

  def current_user
    return nil if session[:session_token].nil?
    @current_user ||= User.find_by_session_token(session[:session_token])
  end
end
