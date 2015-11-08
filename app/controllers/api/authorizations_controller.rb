class Api::AuthorizationsController < ApplicationController
  require 'net/http'
  def echo
    render json: params
  end

  def authorize
    #assumes we have the following: "slack_user_id", "slack_tocken" (session), ""
    CLIENT_ID = ENV['slack_client_id']
    uri = "https://slack.com/oauth/authorize"

    authorize = Authorization.find(user_id: params[:user_id])
    unless authorize
      authorize = Authorization.create(user_id: params[:user_id])
      session[:remember_token] = Authorization.session_token
    end

    redirect_to uri + "?client_id=" + CLIENT_ID + "&scope=" + SCOPE +
    "&redirect_uri=" + base_url + "/api/authorizations/create"
  end

  def destroy
  end

  # uber
  def update
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
