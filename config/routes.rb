Rails.application.routes.draw do
  namespace :api do 
    post :echo, to: 'authorizations#echo' 
  end
end
