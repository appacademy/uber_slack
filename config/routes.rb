Rails.application.routes.draw do
  namesapce :api do 
    post echo, to: 'authorizations#echo' 
  end
end
