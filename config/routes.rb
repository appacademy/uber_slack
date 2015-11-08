Rails.application.routes.draw do
  namespace :api do
    post :echo, to: 'authorizations#echo'
    poost :authorize, to: 'authorizations#authorize'
  end
end
