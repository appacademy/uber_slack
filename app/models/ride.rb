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

class Ride < ActiveRecord::Base
  belongs_to :user,
    class_name: "Authorization",
    foreign_key: :user_id,
    primary_key: :id
end
