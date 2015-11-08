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
  validates :user_id, :uber_auth_token, :presence => true

  def session_token 
    SecureRandom.base64(16)
  end
end
