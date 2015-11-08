require 'uri'
require 'net/http'

class Api::UsersController < ApplicationController
  def authorize
    @user = User.find(slack_token: params[:token])

    if @user.nil?
      # make get request to https://slack.com/oauth/authorize
      # client_id: 14103637812.14111721303
      # scopes: user.read, user.write
      # redirect_uri: http://www.uber-slack-middleware.herokuapp.com/api/authorizations/create
      session[:session_token] = User.session_token
      User.new(slack_token: params[:token], slack_user_id: params[:user_id], session[:session_token])
      redirect_uri "https://login.uber.com/oauth/v2/authorize?response_type=code&client_id=B4K8XNeyIq4qsI0QqCN8INGv7Ztn1XIL"
    end
  end
  # don't need slack OAuth (probably?)
  # def create
  #   params[:code] = 1
  #   if params[:code]
  #     new_params = {}
  #     new_params[:client_id] = '14103637812.14111721303'
  #     new_params[:client_secret] = '3c4865efa823e09adf576086e8e1154a'
  #     new_params[:code] = params[:code]
  #     new_params[:redirect_uri] = 'http://www.uber-slack-middleware.herokuapp.com/api/create'
  #     # Net::HTTP.post_form(URI.parse("https://slack.com/api/oauth.access"), new_params)
  #
  #     uri = URI('https://slack.com/api/oauth.access')
  #
  #     Net::HTTP.start(uri.host, uri.port) do |http|
  #       request = Net::HTTP.post_form(uri, new_params)
  #
  #       response = JSON.parse(http.request(request))
  #     end
  #
  #     User.create(session_token: session[:session_token], slack_token: params['access_token']);
  #   end
  # end

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
