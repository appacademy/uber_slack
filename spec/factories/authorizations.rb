FactoryGirl.define do
  factory :authorization do |f|
    uber_auth_token SecureRandom.urlsafe_base64(8)
  end
end
