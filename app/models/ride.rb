# == Schema Information
#
# Table name: rides
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  surge_confirmation_id :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Ride < ActiveRecord::Base
  belongs_to :user,
    class_name: "Authorization",
    foreign_key: :user_id,
    primary_key: :id
end
