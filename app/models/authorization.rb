class Authorization < ActiveRecord::Base
  validates :user_id, :uber_auth_token, :presence => true
end
