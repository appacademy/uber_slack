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

FactoryGirl.define do
  factory :authorization
end
