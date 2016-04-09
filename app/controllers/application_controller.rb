class ApplicationController < ActionController::Base
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
end
