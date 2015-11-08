class Api::AuthorizationsController < ApplicationController
  def echo
    render json: params
  end

  def authorize
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
