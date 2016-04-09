# == Schema Information
#
# Table name: rides
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  surge_confirmation_id :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  start_latitude        :float
#  start_longitude       :float
#  end_latitude          :float
#  end_longitude         :float
#  product_id            :string
#  request_id            :string
#  surge_multiplier      :float
#  origin_name           :string
#  destination_name      :string
#

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
