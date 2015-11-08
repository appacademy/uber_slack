class Api::AuthorizationsController < ApplicationController
  def echo 
    render json: { " echo data "}
  end 
end
