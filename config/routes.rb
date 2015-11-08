# == Route Map
#
#        Prefix Verb URI Pattern              Controller#Action
#          root GET  /                        static_pages#root
# api_authorize POST /api/authorize(.:format) api/users#authorize {:format=>"json"}
#    api_create POST /api/create(.:format)    api/users#create {:format=>"json"}
#

Rails.application.routes.draw do
  root to: 'static_pages#root'
  namespace :api, defaults: { format: 'json' } do
    post '/authorize', to: 'authorizations#authorize'
<<<<<<< HEAD
=======
    post '/use_uber', to: 'authorizations#use_uber'
    get '/connect_uber', to: 'authorizations#connect_uber'
>>>>>>> cf09713a737c07517bfb37020634cb77ccdb404f
  end
end
