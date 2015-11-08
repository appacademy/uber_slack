class Api::AuthorizationsController < ApplicationController
	before_action :require_authorization, only: :use_uber

  def echo
    render json: params
  end

  def authorize
    # render nil if params[:token] != ENV[slack_token]
    # if auth.nil?
    # 	# find the user
    # 	# validate if user has uber tokens
    # 	# if so, there should be location info
    # 	# call a car for user
    # 	use_uber
    # end
  end

  # this is only for new user, connecting its slack acc w/ uber acc
  # this is the callback for authorizing new user
  def connect_uber
    post_params = {
      'client_secret' => ENV['uber_client_secret'],
      'client_id' 		=> ENV['uber_client_id'],
      'grant_type' 		=> 'authorization_code',
      'redirect_uri' 	=> ENV['uber_callback_url'],
      'code' 					=> params[:code]
    }
    # post request to uber
    resp = Net::HTTP.post_form(URI.parse('https://login.uber.com/oauth/v2/token'), post_params)

    access_token = resp.body['access_token']

    if access_token.nil?
    	render json: resp.body
    else
	    Authorization.find_by(session_token: session[:session_token])
                 	 .update(uber_auth_token: access_token)

	    render text: "uber auth success, access_token: #{access_token}"
	  end
  end

  def use_uber
  	# here order car
  end

  def establish_session
  	auth = Authorization.find_by(slack_user_id: params[:user_id])
  	session[:session_token] = Authorization.create_session_token

  	auth.update(session_token: session[:session_token])

  	redirect_to "https://login.uber.com/oauth/v2/authorize?response_type=code&client_id=#{ENV['uber_client_id']}"
  end

  private

  def require_authorization
  	auth = Authorization.find_by(slack_user_id: params[:user_id])

  	return if auth && auth.uber_registered?

  	if auth.nil?
  		auth = Authorization.new(slack_user_id: params[:user_id])
  		auth.save
  	end

  	if !auth.uber_registered?
  		render text: params[:user_id]
  		# render text: "#{api_activate_url}?user_id=#{auth.slack_user_id}"
  	end
  end
end
