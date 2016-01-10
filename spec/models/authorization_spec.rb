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
