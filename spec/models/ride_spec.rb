describe Ride do
  let(:ride) { build(:ride) }
  it "has a valid factory" do
    expect(ride).to be_valid
  end

  it "belongs to a user" do
    assoc = Ride.reflect_on_association(:user).macro
    expect(assoc).to eq(:belongs_to)
  end
end
