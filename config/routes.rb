Rails.application.routes.draw do
  namespace :api do
    post :echo, to: 'authorizations#echo'
<<<<<<< HEAD
    poost :authorize, to: 'authorizations#authorize'

=======
    post :authorize, to: 'authorizations#authorize'
>>>>>>> 026fa9f5a9b2c31884474d167d73cd98d881f193
  end
end
