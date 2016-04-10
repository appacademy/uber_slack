# == Route Map
#
#        Prefix Verb URI Pattern              Controller#Action
#          root GET  /                        static_pages#root
# api_authorize POST /api/authorize(.:format) api/users#authorize {:format=>"json"}
#    api_create POST /api/create(.:format)    api/users#create {:format=>"json"}
#

Rails.application.routes.draw do
  root to: 'static_pages#root'
  get 'static_pages/user_success', to: 'static_pages#user_success'
  get 'static_pages/admin_success', to: 'static_pages#admin_success'
  get 'static_pages/privacy_policy', to: 'static_pages#privacy_policy'
  namespace :api, defaults: { format: 'json' } do
    post '/authorize', to: 'authorizations#authorize'
    post '/echo', to: 'authorizations#echo'
    post '/use_uber', to: 'authorizations#use_uber'
    get '/connect_uber', to: 'authorizations#connect_uber'
    get '/activate', to: 'authorizations#establish_session'
    get '/connect_slack', to: 'authorizations#connect_slack'
  end
  get "/404" => "errors#not_found"
  get "/500" => "errors#exception"
end
