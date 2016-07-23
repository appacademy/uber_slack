# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  first_name :string
#  last_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#create' do
    it 'enforces presence of email' do
      expect { User.create! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'enforces presence of password' do
      expect { User.create!(email: 'foobar@example.com') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'enforces unique email' do
      User.create!(email: 'foobar@example.com')
      expect { User.create!(email: 'foobar@example.com') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'validates email format' do
      user = User.new(email: 'foobar')
      expect(user.save).to be_falsy

      user.email = 'foobar@example.com'
      expect(user.save).to be_truthy
    end

    it 'downcases email before save' do
      user = User.create!(email: 'Foobar@example.com')
      user.reload
      expect(user.email).to eq 'foobar@example.com'
    end
  end
end
