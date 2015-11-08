class Api::AuthorizationsController < ApplicationController
  require 'net/http'
  def echo
    render json: params
  end

  def authorize
    # render nil if params[:token] != ENV[slack_token]
    @user = Authorization.find_by(slack_user_id: params[:user_id])
    if @user.nil?
      session[:session_token] = Authorization.session_token
      Authorization.new(slack_user_id: params[:user_id], session[:session_token])
      redirect_to "https://login.uber.com/oauth/v2/authorize?response_type=code&client_id=B4K8XNeyIq4qsI0QqCN8INGv7Ztn1XIL"
    end
  end

  # uber
  def create
    params = {
      client_secret: ENV['uber_client_secret'],
      client_id:     ENV['uber_client_id'],
      grant_type:    'authorization_code',
      # redirect_uri   ENV[''],
      code:          params[:code]
    }
    # post request to uber
    resp = Net::HTTP.post_form(URI.parse('https://login.uber.com/oauth/v2/token'), params)

    access_token = resp['access_token']

    Authorization.find_by(session_token: session[:session_token])
                 .update(uber_auth_token: access_token)

    render text: "uber auth success, access_token: #{access_token}"
  end
end
