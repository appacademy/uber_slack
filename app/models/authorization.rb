# == Schema Information
#
# Table name: authorizations
#
#  id                  :integer          not null, primary key
#  slack_user_id       :string
#  slack_auth_token    :string
#  oauth_session_token :string
#  uber_user_id        :integer
#  uber_auth_token     :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  session_token       :string
#  webhook             :string
#

class Authorization < ActiveRecord::Base
  has_many :rides,
    class_name: "Ride",
    foreign_key: :user_id,
    primary_key: :id

  def self.create_session_token
    SecureRandom.urlsafe_base64(16)
  end

  def uber_registered?
  	!self.uber_auth_token.nil?
  end
end
