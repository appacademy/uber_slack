class Api::AuthorizationsController < ApplicationController
  def echo
    render json: params
  end

  def authorize
    #assumes we have the following: "slack_user_id", "slack_tocken" (session), ""
    uri = "https://slack.com/oauth/authorize"

    authorize = Authorization.find(user_id: params[:user_id])
    if authorize
    else
      authorize = Authorization.create(user_id: params[:user_id])
    end

    redirect_to uri
    

  end
