class Api::AuthorizationsController < ApplicationController
  rescue_from RuntimeError, with: :render_error

  before_action :verify_slack_token, only: :use_uber
  before_action :require_authorization, only: :use_uber
  before_action :ensure_fresh_access_token, only: :use_uber

  SUPPORT_PAGE = "https://github.com/appacademy/uber_slack/issues"

  def echo
    render json: params
  end

  # Action for user commands.
  def use_uber
    auth = Authorization.find_by(slack_user_id: params[:user_id])
    response_url = slack_params[:response_url]
    uber_command = UberCommand.new(auth.uber_auth_token, auth.id, response_url)
    resp = uber_command.run(slack_params[:text])

    render json: resp
  rescue RestClient::Exception => e
    # UberCommand should handle this, but it might have missed something
    Rollbar.error(e,
                  auth: auth,
                  response_url: response_url,
                  uber_command: uber_command,
                  resp: e.response)
    render json: [
             "Sorry, there was a problem with your request.",
             "The error message is as follows: #{e.message}",
             "Please let us know about what caused this at #{SUPPORT_PAGE}."
           ].join(" ")
  end

  def render_error(error)
    Rollbar.error(error)

    error_msg = [
      "Sorry, we encountered an error!",
      "Please let us know about what caused this at #{SUPPORT_PAGE}.",
      "If you requested a pickup, enter */uber status* to see if the request went through."
    ].join(" ")
    render json: { text: error_msg }
  end

  def connect_uber
    # After user has clicked "yes" on Uber OAuth page
    tokens = UberAPI.request_user_access_token(params[:code])
    auth = update_authorization(tokens)
    signup_success(auth.slack_response_url)

    redirect_to static_pages_user_success_url
  end

  def establish_session
    # when authorizing with Uber:  first save session_token, then redirect to Uber OAuth page.
    auth = Authorization.find_by(slack_user_id: params[:user_id])
    raise RunTimeError if auth.nil?

    session[:session_token] = Authorization.create_session_token
    session[:slack_response_url] = slack_params[:response_url]

    auth.update(session_token: session[:session_token])

    redirect_to uber_first_auth_url
  end

  def current_user
    @user ||= Authorization.find_by(slack_user_id: params[:user_id])
  end

  def connect_slack
    SlackClient.add_to_channel(slack_params[:code])
    redirect_to static_pages_admin_success_url
  rescue SlackClient::Exception => e
    Rollbar.error("connect_uber", resp: e.response, slack_auth_params: slack_auth_params)
    render text: "Sorry, something went wrong on our end."
  end

  private

  def verify_slack_token
    #verify request to use_uber is from slack.
    unless slack_params[:token] == ENV['slack_app_token']
      render json: {error: "Missing slack_app_token", params: slack_params}
    end
  end

  def slack_params
    params.permit(:user_id, :code, :token, :text, :response_url)
  end

  def require_authorization
    # if user is not signed up, give a link to sign up.
    auth = Authorization.find_by(slack_user_id: params[:user_id])
    return if auth && auth.uber_registered?

    auth = register_new_user if auth.nil?
    render text: uber_oauth_str_url(auth.slack_user_id)
  end

  def ensure_fresh_access_token
    auth = Authorization.find_by(slack_user_id: params[:user_id])
    if auth.uber_access_token_expiration_time < Time.now
      UberAPI.refresh_access_token(auth)
    end
  end

  def register_new_user
    # save the slack response url so we can send an alert upon uber auth success
    Authorization.create!(slack_user_id: params[:user_id], slack_response_url: params[:response_url])
  end

  def uber_oauth_str_url(slack_user_id)
    username = params[:user_name]
    url = "#{api_activate_url}?user_id=#{slack_user_id}"
    "Hey @#{username}! Looks like this is your first ride from Slack. Go <#{url}|here> to activate."
  end

  def uber_first_auth_url
    url = "#{ENV['uber_authorize_url']}#{ENV['uber_client_id']}"
    url += "&scope=request+surge_accept" unless ENV['hostname'].match("staging")
    url
  end

  def notifications
    # Take the params and redirect data to slack
  end

  def update_authorization(response)
    access_token = response['access_token']
    refresh_token = response['refresh_token']
    expires_in = response['expires_in']

    Authorization.find_by(session_token: session[:session_token]).tap do |auth|
      auth.update!(
        uber_auth_token: access_token,
        uber_refresh_token: refresh_token,
        uber_access_token_expiration_time: Time.now + expires_in
      )
    end
  end

  def signup_success(response_url)
    slack_response_payload = { text: 'You can now request a ride from Slack!' }

    RestClient.post(
      response_url,
      slack_response_payload.to_json,
      "Content-Type" => :json
    )

  rescue RestClient::Exception => e
    Rollbar.error(e, resp: e.response)
  end
end
