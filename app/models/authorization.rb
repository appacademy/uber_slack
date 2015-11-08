# == Schema Information
#
# Table name: authorizations
#
#  id                  :integer          not null, primary key
#  slack_user_id       :integer
#  slack_auth_token    :string
#  oauth_session_token :string
#  uber_user_id        :integer
#  uber_auth_token     :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Authorization < ActiveRecord::Base
  def self.session_token
    SecureRandom.urlsafe_base64(16)
  end
end
