class UberAPI
  BASE_PARAMS   = {
    'client_secret' => ENV['uber_client_secret'],
    'client_id'     => ENV['uber_client_id'],
    'grant_type'    => 'authorization_code',
    'redirect_uri'  => ENV['uber_callback_url']
  }.freeze

  def self.request_user_access_token(code)
    # After user has clicked "yes" on Uber OAuth page
    post_params = BASE_PARAMS.merge({ 'code' => code })

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
      RestClient.post(auth.slack_response_url, reply )
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
end