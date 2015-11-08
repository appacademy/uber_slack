# == Schema Information
#
# Table name: authorizations
#
#  id                  :integer          not null, primary key
#  slack_user_id       :integer
#  slack_auth_token    :string
#  oauth_session_token :string     why did have this?
#  uber_user_id        :integer
#  uber_auth_token     :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  session_token       :string
#  webhook             :string
#

class Authorization < ActiveRecord::Base
  def self.create_session_token
    SecureRandom.urlsafe_base64(16)
  end

  def uber_registered?
  	!self.uber_auth_token.nil?
  end
end
