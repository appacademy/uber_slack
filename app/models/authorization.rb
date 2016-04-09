# == Schema Information
#
# Table name: authorizations
#
#  id                                :integer          not null, primary key
#  slack_user_id                     :string
#  uber_auth_token                   :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  session_token                     :string
#  uber_refresh_token                :string
#  uber_access_token_expiration_time :datetime
#  slack_response_url                :string
#

# slack_user_id, session_token, uber_auth_token
class Authorization < ActiveRecord::Base
  has_many :rides,
    class_name: "Ride",
    foreign_key: :user_id,
    primary_key: :id

  def self.create_session_token
    SecureRandom.urlsafe_base64(16)
  end

  def uber_registered?
  	!!uber_auth_token
  end
end
