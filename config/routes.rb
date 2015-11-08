Rails.application.routes.draw do
<<<<<<< HEAD
  root to: 'static_pages#root'
  namespace :api, defaults: { format: 'json' } do
    post '/authorize', to: 'users#authorize'
    post '/create', to: 'users#create'
=======
  namespace :api do
    post :echo, to: 'authorizations#echo'
    post :authorize, to: 'authorizations#authorize'
>>>>>>> 07d83813c24ae2f1f6279e7e0bda0acf89265b55
  end
end
