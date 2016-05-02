class UberAPI
  BASE_PARAMS = {
    'client_secret' => ENV['uber_client_secret'],
    'client_id'     => ENV['uber_client_id'],
    'grant_type'    => 'authorization_code',
    'redirect_uri'  => ENV['uber_callback_url']
  }.freeze

  BASE_URL = ENV["uber_base_url"]


  def self.request_user_access_token(code)
    # After user has clicked "yes" on Uber OAuth page
    post_params = BASE_PARAMS.merge("code" => code)

    # post request to uber to trade code for user access token
    resp = RestClient.post(ENV['uber_oauth_url'], post_params)
    JSON.parse(resp.body)
  end

  def self.connect_uber(code)
    # After user has clicked "yes" on Uber OAuth page
    post_params = BASE_PARAMS.merge({ 'code' => code })

    # post request to uber to trade code for user access token
    resp = RestClient.post(ENV['uber_oauth_url'], post_params)
    response = JSON.parse(resp.body)
    if response["access_token"]
      auth = update_authorization(response)

      # sign up success, prompt user that they can order uber now
      reply = { text: 'You can now request a ride from Slack!' }
      RestClient.post(auth.slack_response_url, reply)
    else
      render json: { status: "Error: no access token", body: resp.body }
    end
  rescue RestClient::Exception => e
    Rollbar.error(e, post_params: post_params, resp: e.response)
    if e.response.code == 500
      response = { text: "Sorry, there was a problem authenticating your account." }
    # render text: "Sorry, there was a problem authenticating your account."
    else
      response = { text: "Sorry, something went wrong on our end." }
      # render text: "Sorry, something went wrong on our end."
    end

    RestClient.post(auth.slack_response_url, response.to_json)
  end

  def self.get_ride_estimate(body, bearer_header)
    response = RestClient.post(
      "#{BASE_URL}/v1/requests/estimate",
      body.to_json,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: :json
    )

    JSON.parse(response.body)
  end

  def self.get_products_for_lat_lng(lat, lng)
    uri = Addressable::URI.parse("#{BASE_URL}/v1/products")
    uri.query_values = { 'latitude' => lat, 'longitude' => lng }
    resource = uri.to_s

    result = RestClient.get(
      resource,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )

    JSON.parse(result.body)
  end

  def self.cancel_ride(request_id, bearer_header)
    begin
      RestClient.delete(
        "#{BASE_URL}/v1/requests/#{request_id}",
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )
    rescue RestClient::Exception => e
      Rollbar.error(e, "UberCommand#cancel")
    end
  end

  def self.accept_surge(ride)
    body = {
      "start_latitude" => ride.start_latitude,
      "start_longitude" => ride.start_longitude,
      "end_latitude" => ride.end_latitude,
      "end_longitude" => ride.end_longitude,
      "surge_confirmation_id" => ride.surge_confirmation_id,
      "product_id" => ride.product_id
    }
    begin
      RestClient.post(
        "#{BASE_URL}/v1/requests",
        body.to_json,
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )
    rescue RestClient::Exception => e
      Rollbar.error(e, "UberCommand#accept")
    end
  end

  def self.request_map_link(request_id)
    begin
      RestClient.get(
        "#{BASE_URL}/v1/requests/#{request_id}/map",
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )
    rescue RestClient::Exception => e
      Rollbar.error(e, "UberCommand#share")
      return "Sorry, we weren't able to get the link to share your ride."
    end
  end

  def self.get_ride_status(request_id)
    resp = RestClient.get(
      "#{BASE_URL}/v1/requests/#{request_id}",
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )
    JSON.parse(resp.body)
  end
end
