require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#create' do
    it 'enforces presence of email' do
      expect { User.create! }.to raise_error
    end

    it 'enforces unique email' do
      User.create!(email: 'foobar@example.com')
      expect { User.create!(email: 'foobar@example.com') }.to raise_error
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
