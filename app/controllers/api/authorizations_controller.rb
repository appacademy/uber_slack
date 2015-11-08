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
    resp = RestClient.post('https://login.uber.com/oauth/v2/token', post_params)
    # resp = Net::HTTP.post_form(URI.parse('https://login.uber.com/oauth/v2/token'), post_params)

    access_token = JSON.parse(resp.body)['access_token']

    if access_token.nil?
    	render json: resp.body
    else
	    Authorization.find_by(session_token: session[:session_token])
                 	 .update(uber_auth_token: access_token)

	    render json: resp.body
	  end
  end

  def use_uber
  	# here order car
    # @bearer_token = Authorization.find_by(session_token: session[:session_token])[:uber_auth_token]

    #use geocoder to extract lat lng from params[:text]
    # @lat = Geocoder.search(params[:lat])[0].data["geometry"]["location"]["lat"]
    # @lng = Geocoder.search(params[:lng])[0].data["geometry"]["location"]["lng"]

    @bearer_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZXMiOlsicHJvZmlsZSIsImhpc3RvcnlfbGl0ZSIsImhpc3RvcnkiLCJyZXF1ZXN0Il0sInN1YiI6ImJkNjYxMWRiLWM1MGQtNGQyYi04NDNhLWExNWNiOTY4NjI2NyIsImlzcyI6InViZXItdXMxIiwianRpIjoiNzQ0MjQzYzYtOGE4OS00ZTcyLWJjMDktZDlmNDNmMThiZjZlIiwiZXhwIjoxNDQ5NjExMDg0LCJpYXQiOjE0NDcwMTkwODQsInVhY3QiOiJBWjRYVmIzRm5TWlBMdnZmWWNSbHBtQzdyeDB5WmoiLCJuYmYiOjE0NDcwMTg5OTQsImF1ZCI6IkI0SzhYTmV5SXE0cXNJMFFxQ044SU5HdjdadG4xWElMIn0.RlFuiCJrCcitGSJy4GtQzvhnCynl1jQ30aqiLnOWptio9QVYkiQJDdNMrrl6t63PQuJjfiKyjjCnRrFUOrDkvJBH4NB5D-dRKd19wW2izPw01rTJJEA25vyk3qup64bQY95dXKjIAgWRsqZGI6ee-aJEgPy4MyhWbtp2du0PmMhy8Udi-P-H-syzoF7HpJxtecCMDtKbUpCGwOx12c-6TRXhde6BArrCrh36P0Dj8YBbotahDL5MgsOrPJZvWTUfrqm4Jw9ZI77VieEzkd2GVXO_tAmWo6TvaoqxS1-BHMBLICwcLKm_GmFKYAPYvQbEoztUaIMtgkxpep3_um56uA"
    @start_lat = Geocoder.search("2775 park street, berkeley ca 94702")[0].data["geometry"]["location"]["lat"]
    @start_lng = Geocoder.search("2775 park street, berkeley ca 94702")[0].data["geometry"]["location"]["lng"]

    get_products_params = {
      'latitude' => @start_lat.to_s,
      'longitude' => @start_lng.to_s
    }

    header = {Authorization: ("Bearer " + @bearer_token),
              params: get_products_params}

    result = RestClient.get("https://sandbox-api.uber.com/v1/products", header)
    render text: result.body
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
  		render text: "#{api_activate_url}?user_id=#{auth.slack_user_id}"
  	end
  end

  def notifications
    # Take the params and redirect data to slack
  end
end
