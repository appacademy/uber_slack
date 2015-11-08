class Api::AuthorizationsController < ApplicationController
  def echo
    render json: params
  end

  def authorize
  end
