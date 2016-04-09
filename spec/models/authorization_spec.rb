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

describe Authorization do
  let(:auth) { build(:authorization) }

  it "has a valid factory" do
    expect(auth).to be_valid
  end

  it "has many rides" do
    assoc = Authorization.reflect_on_association(:rides).macro
    expect(assoc).to eq(:has_many)
  end

  it "can generate a random session token" do
    tokens = 5.times.inject([]) do |acc, _|
      acc << Authorization.create_session_token
    end
    expect(tokens.uniq.length).to be > 1
  end

  it "replies correctly whether it's been registered with Uber" do
    expect(auth.uber_registered?).to be !!auth.uber_auth_token
  end
end
