Rails.application.routes.draw do
  root to: 'static_pages#root'
  namespace :api, defaults: { format: 'json' } do
    post '/authorize', to: 'users#authorize'
    post '/create', to: 'users#create'
  end
end
