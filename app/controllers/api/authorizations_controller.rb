class Api::AuthorizationsController < ApplicationController
  require 'net/http'
  def echo
    render json: params
  end

  def authorize
    #assumes we have the following: "slack_user_id", "slack_tocken" (session), ""
    CLIENT_ID = "aslkjdjasdlkjasdAAAAA"
    uri = "https://slack.com/oauth/authorize"

    authorize = Authorization.find(user_id: params[:user_id])
    if authorize
    else
      authorize = Authorization.create(user_id: params[:user_id])
    end

    redirect_to uri + "?client_id=" + CLIENT_ID + "&scope=" + SCOPE +
    "&redirect_uri=" + base_url + "/api/authorizations/create"
  end
